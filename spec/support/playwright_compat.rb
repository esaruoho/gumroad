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

    # Strategy 1: click a <label> by text
    begin
      find("label", text: locator, exact_text: true, wait: 2, **clean_opts).click
      return
    rescue Capybara::ElementNotFound
      # continue to next strategy
    end

    # Strategy 2: click any element with role="radio"
    begin
      find("[role='radio']", text: locator, exact_text: true, wait: 2, **clean_opts).click
      return
    rescue Capybara::ElementNotFound
      # continue to next strategy
    end

    # Strategy 3: click_on (links/buttons)
    begin
      click_on(locator, wait: 2, **clean_opts)
      return
    rescue Capybara::ElementNotFound
      # continue to next strategy
    end

    # Strategy 4: find any element with matching text and click it
    find("*", text: locator, exact_text: true, wait: 2, **clean_opts).click
  end
end

RSpec.configure do |config|
  config.include PlaywrightChooseFallback, type: :system
end
