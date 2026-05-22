# frozen_string_literal: true

require "date"
require "time"

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
  rescue Playwright::Error, Playwright::TimeoutError => e
    raise if e.is_a?(Playwright::Error) && !(e.message.include?("not an <input>") ||
                 e.message.include?("role allowing") ||
                 e.message.include?("contenteditable"))

    raise ArgumentError, "choose fallback requires a locator" unless locator

    clean_opts = options.except(:option, :currently_with, :allow_label_click)
    clean_opts[:wait] = 2 unless clean_opts.key?(:wait)
    clean_opts[:match] = :first unless clean_opts.key?(:match)

    # Strategy 1: click a <label> by text
    begin
      find("label", text: locator, exact_text: true, **clean_opts).click
      return
    rescue Capybara::ElementNotFound
      # continue to next strategy
    end

    # Strategy 2: click any element with role="radio" by text or aria-label
    begin
      find("[role='radio'], [role='menuitemradio']", text: locator, exact_text: true, **clean_opts).click
      return
    rescue Capybara::ElementNotFound
      # continue to next strategy
    end

    # Strategy 2b: click role="radio" by aria-label (e.g. star ratings with icon-only content)
    begin
      find(:css, "[role='radio'][aria-label='#{locator}'], [role='menuitemradio'][aria-label='#{locator}']", **clean_opts).click
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

    # Strategy 5: find by aria-label (elements with icon-only content)
    begin
      find(:css, "[aria-label='#{locator.to_s}']", **clean_opts).click
      return
    rescue Capybara::ElementNotFound
      # continue to final strategy
    end

    # Strategy 6: click the deepest exact text node instead of a matching parent.
    click_deepest_text_match(locator.to_s, **clean_opts)
  end

  private
    def click_deepest_text_match(text, **options)
      candidates = all(:css, "*", text:, exact_text: true, **options.except(:match))
      candidate = candidates.to_a.reverse.find do |element|
        element.text(:all).gsub(/[[:space:]]+/, " ").strip == text &&
          element.all(:css, "*", text:, exact_text: true, wait: false).empty?
      end

      (candidate || find(:css, "*", text:, exact_text: true, **options)).click
    end
end

module PlaywrightFillInCompat
  TEMPORAL_INPUT_TYPES = %w[date datetime-local time month week].freeze

  def fill_in(locator = nil, with:, currently_with: nil, fill_options: {}, **find_options)
    return super unless playwright_driver?

    find_options[:with] = currently_with if currently_with
    find_options[:allow_self] = true if locator.nil?
    field = find(:fillable_field, locator, **find_options)
    value = playwright_fill_value(field, with)

    if playwright_type_fill?(field, value, fill_options)
      playwright_type_fill(field, value)
    else
      begin
        field.set(value, **fill_options)
      rescue Playwright::Error => e
        raise unless playwright_temporal_input?(field) && e.message.match?(/malformed/i)

        playwright_type_fill(field, value)
      end
    end
  end

  private
    def playwright_driver?
      Capybara.current_session.driver.respond_to?(:with_playwright_page)
    end

    def playwright_type_fill?(field, value, fill_options)
      fill_options.empty? &&
        %w[input textarea].include?(field.tag_name) &&
        field[:inputmode] == "decimal" &&
        value.to_s.match?(/[^\d.]/)
    end

    def playwright_type_fill(field, value)
      field.execute_script("this.focus(); this.select();")
      field.send_keys(:backspace, value.to_s)
    end

    def playwright_fill_value(field, value)
      return value unless playwright_temporal_input?(field)

      string = value.to_s.strip
      return value if string.empty?

      case field[:type].to_s
      when "date"
        format_date_value(value)
      when "datetime-local"
        format_datetime_local_value(value)
      when "time"
        format_time_value(value)
      when "month"
        format_month_value(value)
      when "week"
        format_week_value(value)
      else
        value
      end
    end

    def playwright_temporal_input?(field)
      field.tag_name == "input" && TEMPORAL_INPUT_TYPES.include?(field[:type].to_s)
    end

    def format_date_value(value)
      return value.strftime("%Y-%m-%d") if value.respond_to?(:strftime) && !value.is_a?(String)

      string = value.to_s.strip
      return string if string.match?(/\A\d{4}-\d{2}-\d{2}\z/)

      parse_date_value(string)&.strftime("%Y-%m-%d") || value
    end

    def format_datetime_local_value(value)
      return value.strftime("%Y-%m-%dT%H:%M") if value.respond_to?(:strftime) && !value.is_a?(String)

      string = value.to_s.strip
      return string if string.match?(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?::\d{2}(?:\.\d+)?)?\z/)

      parse_datetime_value(string)&.strftime("%Y-%m-%dT%H:%M") ||
        parse_date_value(string)&.strftime("%Y-%m-%dT00:00") ||
        value
    end

    def format_time_value(value)
      return value.strftime("%H:%M") if value.respond_to?(:strftime) && !value.is_a?(String)

      string = value.to_s.strip
      return string if string.match?(/\A\d{2}:\d{2}(?::\d{2}(?:\.\d+)?)?\z/)

      parse_time_value(string)&.strftime("%H:%M") || value
    end

    def format_month_value(value)
      return value.strftime("%Y-%m") if value.respond_to?(:strftime) && !value.is_a?(String)

      string = value.to_s.strip
      return string if string.match?(/\A\d{4}-\d{2}\z/)

      parse_date_value(string)&.strftime("%Y-%m") || parse_month_value(string)&.strftime("%Y-%m") || value
    end

    def format_week_value(value)
      return value.strftime("%G-W%V") if value.respond_to?(:strftime) && !value.is_a?(String)

      string = value.to_s.strip
      return string if string.match?(/\A\d{4}-W\d{2}\z/)

      parse_date_value(string)&.strftime("%G-W%V") || value
    end

    def parse_date_value(value)
      %w[%m/%d/%Y %Y-%m-%d].each do |format|
        return Date.strptime(value, format)
      rescue ArgumentError
        next
      end

      nil
    end

    def parse_time_value(value)
      parse_datetime_value(value) ||
        parse_clock_value(value)
    end

    def parse_datetime_value(value)
      [
        "%Y-%m-%dT%H:%M",
        "%Y-%m-%d %H:%M",
        "%m/%d/%Y\t%I:%M%p",
        "%m/%d/%Y %I:%M%p",
        "%m/%d/%Y %I:%M %p",
        "%m/%d/%Y %H:%M"
      ].each do |format|
        return Time.strptime(value, format)
      rescue ArgumentError
        next
      end

      nil
    end

    def parse_clock_value(value)
      [
        "%I:%M%p",
        "%I:%M %p",
        "%H:%M"
      ].each do |format|
        return Time.strptime(value, format)
      rescue ArgumentError
        next
      end

      nil
    end

    def parse_month_value(value)
      Date.strptime(value, "%m/%Y")
    rescue ArgumentError
      nil
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
  # Selenium's `attribute` also returns DOM properties (e.g. `validationMessage`,
  # `checked`, `value`) when no HTML attribute exists. Playwright's `get_attribute`
  # only returns HTML attributes. Fall back to JS property access for compat.
  def attribute(name)
    val = get_attribute(name)
    return val unless val.nil?

    # Try DOM property access (covers validationMessage, checked, value, etc.)
    evaluate("el => { const v = el[el.__propName]; return v === undefined ? null : String(v) }".sub("el.__propName", "el['#{name}']")) rescue nil
  end

  # Selenium exposes `css_value(prop)` for computed styles. Playwright doesn't
  # have this method — bridge it via JS getComputedStyle.
  def css_value(property)
    evaluate("el => getComputedStyle(el).getPropertyValue('#{property}')") rescue nil
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
    raise unless playwright_driver?

    click_first_command(locator, **options)
  rescue Playwright::TimeoutError
    raise unless playwright_driver?

    # The union :command selector (button+link+menuitem+tab_button) can be
    # slow in Playwright, causing timeouts. Try individual selectors which
    # are faster and more targeted.
    click_individual_selectors(locator, **options)
  end

  def click_on(locator = nil, **options)
    super
  rescue Capybara::Ambiguous
    raise unless playwright_driver?

    click_first_command(locator, **options)
  rescue Playwright::TimeoutError
    raise unless playwright_driver?

    click_individual_selectors(locator, **options)
  end

  private
    def playwright_driver?
      Capybara.current_session.driver.respond_to?(:with_playwright_page)
    end

    def click_first_command(locator, **options)
      find(:command, locator, **options.merge(match: :first)).click
    end

    def click_individual_selectors(locator, **options)
      opts = options.merge(match: :first, wait: 2)

      # Try :button first (most common), then :link, then :menuitem
      %i[button link menuitem].each do |selector|
        find(selector, locator, **opts).click
        return
      rescue Capybara::ElementNotFound, Playwright::TimeoutError
        next
      end

      # Final attempt: any clickable element by text
      find(:css, "button, a, [role='button'], [role='link'], [role='menuitem']",
           text: locator, exact_text: false, **opts).click
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
Capybara::Node::Actions.prepend(PlaywrightChooseFallback)
Capybara::Node::Actions.prepend(PlaywrightFillInCompat)
Capybara::Node::Actions.prepend(PlaywrightAmbiguousCommandFallback)
