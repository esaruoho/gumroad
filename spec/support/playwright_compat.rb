# frozen_string_literal: true

# Playwright is stricter than Selenium about `choose` — it requires a real
# <input type="radio"> or an element with an appropriate ARIA role.
# Many Gumroad specs use `choose("Label text")` on custom React radio
# components or menu items without native radio inputs. In Selenium,
# `choose` tolerated this because it just clicked any matching element.
#
# This patch catches Playwright::Error from `choose` and falls back to
# clicking a matching element by text, preserving existing spec behavior.
module PlaywrightChooseFallback
  def choose(locator = nil, **options)
    super
  rescue Playwright::Error => e
    raise unless e.message.include?("not an <input>") ||
                 e.message.include?("role allowing") ||
                 e.message.include?("contenteditable")

    raise ArgumentError, "choose fallback requires a locator" unless locator

    clean_opts = options.except(:option, :currently_with)
    clean_opts[:wait] = 2 unless clean_opts.key?(:wait)
    clean_opts[:match] = :first unless clean_opts.key?(:match)

    # Strategy 1: click a <label> by text
    begin
      find("label", text: locator, exact_text: true, **clean_opts).click
      return
    rescue Capybara::ElementNotFound
      # continue to next strategy
    end

    # Strategy 2: click any element with role="radio"
    begin
      find("[role='radio'], [role='menuitemradio']", text: locator, exact_text: true, **clean_opts).click
      return
    rescue Capybara::ElementNotFound
      # continue to next strategy
    end

    # Strategy 3: click_on (links/buttons)
    begin
      click_on(locator, **clean_opts)
      return
    rescue Capybara::ElementNotFound
      # continue to next strategy
    end

    # Strategy 4: click an actionable ARIA item by text
    begin
      find("[role='option'], [role='menuitem'], [role='checkbox'], [role='switch'], [role='tab']",
           text: locator,
           exact_text: true,
           **clean_opts).click
      return
    rescue Capybara::ElementNotFound
      # continue to final strategy
    end

    # Strategy 5: click the deepest exact text node instead of a matching parent
    text = locator.to_s
    leaf_text_xpath = XPath.descendant[XPath.string.n.equals(text) & ~XPath.descendant[XPath.string.n.equals(text)]]
    find(:xpath, leaf_text_xpath, **clean_opts).click
  end
end

module PlaywrightElementHandleCompat
  def send_keys(*keys)
    Capybara::Playwright::Node::SendKeys.new(self, keys).execute
  end

  def clear
    fill("")
  end

  # Selenium uses `attribute(name)`, Playwright uses `get_attribute(name)`.
  # Bridge the gap so specs calling `.attribute` work with both drivers.
  def attribute(name)
    get_attribute(name)
  end
end

Playwright::ElementHandle.prepend(PlaywrightElementHandleCompat) if defined?(Playwright::ElementHandle)

# Playwright's stricter DOM traversal can find hidden duplicate elements
# where Selenium only found one, causing Capybara::Ambiguous errors on
# the `:command` selector (which unions button+link+menuitem+tab_button).
# This fallback catches the ambiguity and retries with `match: :first`.
module PlaywrightAmbiguousCommandFallback
  def click_command(locator = nil, **options)
    super
  rescue Capybara::Ambiguous
    options[:match] = :first
    find(:command, locator, **options).click
  end
end

# Playwright may raise on hover when elements are detached mid-transition.
# Retry once after a short pause.
module PlaywrightHoverCompat
  def hover
    super
  rescue StandardError => e
    raise unless defined?(Playwright::Error) && (e.is_a?(Playwright::Error) || e.message.include?("Element is not attached"))
    sleep 0.2
    super
  end
end

Capybara::Node::Element.prepend(PlaywrightHoverCompat)

RSpec.configure do |config|
  config.include PlaywrightChooseFallback, type: :system
  config.include PlaywrightAmbiguousCommandFallback, type: :system
end
