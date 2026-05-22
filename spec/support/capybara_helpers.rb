# frozen_string_literal: true

module CapybaraHelpers
  def wait_for_valid(javascript_expression)
    page.document.synchronize do
      raise Capybara::ElementNotFound unless page.evaluate_script(javascript_expression)
    end
  end

  def wait_for_visible(selector)
    wait_for_valid %($('#{selector}:visible').length > 0)
  end

  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.05 until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script(<<~EOS)
      ((typeof window.jQuery === 'undefined') || jQuery.active === 0) && !window.__activeRequests
    EOS
  end

  DISABLE_ANIMATIONS_JS = <<~JS
    if (!document.getElementById('__disable_animations')) {
      const style = document.createElement('style');
      style.id = '__disable_animations';
      style.textContent = '*, *::before, *::after { animation-duration: 0s !important; animation-delay: 0s !important; transition-duration: 0s !important; transition-delay: 0s !important; }';
      document.head.appendChild(style);
    }
  JS

  def visit(url)
    page.visit(url)
    return if Capybara.current_driver == :rack_test
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.05 until page.evaluate_script("document.readyState") == "complete"
    end
    # With Vite, JS is loaded via ESM (type="module") which is deferred —
    # modules execute after DOMContentLoaded but may not have finished by
    # the time readyState == "complete". Wait for the Inertia React app to
    # mount (the #app div gets children) or for non-Inertia pages to load
    # their JS entry points.
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.05 until page.evaluate_script(<<~JS)
        (function() {
          var app = document.getElementById('app');
          if (!app) return true;
          return app.children.length > 0;
        })()
      JS
    end
    disable_animations
    wait_for_ajax
  end

  def wait_until_true(sleep_interval: 1)
    Timeout.timeout(Capybara.default_max_wait_time) do
      until yield
        sleep sleep_interval
      end
    end
  end

  def js_style_encode_uri_component(comp)
    # CGI.escape encodes spaces to "+"
    # but encodeURIComponent in JS encodes them to "%20"
    CGI.escape(comp).gsub("+", "%20")
  end

  def fill_in_color(field, color)
    field.execute_script("Object.getOwnPropertyDescriptor(Object.getPrototypeOf(this), 'value').set.call(this, arguments[0]); this.dispatchEvent(new Event('input', { bubbles: true }))", color)
  end

  def have_nth_table_row_record(n, text, exact_text: true)
    have_selector("tbody tr:nth-child(#{n}) > td", text:, exact_text:, normalize_ws: true)
  end

  def get_client_time_zone
    page.evaluate_script("Intl.DateTimeFormat().resolvedOptions().timeZone")
  end

  def unfocus
    find("body").click
  end

  def fill_in_datetime(field, with:)
    element = find_field(field)
    element.click
    element.execute_script("this.value = arguments[0]; this.dispatchEvent(new Event('blur', {bubbles: true}));", with)
  end

  def accept_browser_dialog
    if page.driver.respond_to?(:with_playwright_page)
      # Playwright auto-accepts dialogs via dialog_event_handler.
      # If a dialog is already queued, this is a no-op.
      page.driver.accept_modal(:confirm, wait: 1) rescue nil
    else
      page.driver.browser.switch_to.alert.accept
    end
  rescue StandardError
    sleep 0.5
    retry
  end

  # Reads the flash/toast alert message and immediately dismisses it.
  # Use this instead of `have_alert` when the alert overlays content
  # you need to interact with next — it prevents the 5s auto-dismiss
  # from blocking clicks on elements underneath.
  #
  # Usage:
  #   click_on "Save"
  #   expect(flash_message).to eq "Changes saved!"
  #   # alert is now dismissed, safe to interact with content beneath it
  def flash_message
    toast = find("[data-testid='toast-alert']")
    message = toast.text
    within(toast) { find('button[aria-label="Close"]').click }
    message
  end

  # Waits for checkout surcharges to load after country/ZIP/tax ID changes.
  # The checkout form debounces these at 300ms before firing the API call.
  def wait_for_checkout_surcharges_loaded
    sleep 0.4 # debounce (300ms) + margin
    wait_for_ajax
  end

  def with_throttled_network(fixture_file, factor: 4)
    throughput = (File.size(fixture_file) * factor)
    if page.driver.respond_to?(:with_playwright_page)
      page.driver.with_playwright_page do |pw_page|
        context = pw_page.context
        # Playwright doesn't have native network throttling, but CDP works via Chromium
        client = context.new_cdp_session(pw_page)
        client.send_message("Network.enable")
        client.send_message("Network.emulateNetworkConditions",
          offline: false, latency: 0,
          downloadThroughput: throughput, uploadThroughput: throughput)
      end
      yield
      page.driver.with_playwright_page do |pw_page|
        client = pw_page.context.new_cdp_session(pw_page)
        client.send_message("Network.emulateNetworkConditions",
          offline: false, latency: 0,
          downloadThroughput: -1, uploadThroughput: -1)
      end
    else
      page.driver.browser.execute_cdp("Network.enable")
      page.driver.browser.execute_cdp("Network.emulateNetworkConditions", offline: false, latency: 0, downloadThroughput: throughput, uploadThroughput: throughput)
      yield
      page.driver.browser.execute_cdp("Network.emulateNetworkConditions", offline: false, latency: 0, downloadThroughput: -1, uploadThroughput: -1)
    end
  end

  # ── Cookie & browser helpers (Playwright + Selenium compatible) ──────

  def get_cookie_value(name)
    if page.driver.respond_to?(:with_playwright_page)
      page.driver.with_playwright_page do |pw_page|
        cookies = pw_page.context.cookies
        cookie = cookies.find { |c| c["name"] == name }
        cookie&.dig("value")
      end
    else
      Capybara.current_session.driver.browser.manage.all_cookies.find { |c| c[:name] == name }&.[](:value)
    end
  end

  def get_all_cookies
    if page.driver.respond_to?(:with_playwright_page)
      page.driver.with_playwright_page do |pw_page|
        pw_page.context.cookies.map { |c| c.transform_keys(&:to_sym) }
      end
    else
      Capybara.current_session.driver.browser.manage.all_cookies
    end
  end

  def clear_browser_cookies
    if page.driver.respond_to?(:with_playwright_page)
      page.driver.with_playwright_page do |pw_page|
        pw_page.context.clear_cookies
      end
    else
      Capybara.current_session.driver.browser.manage.delete_all_cookies
    end
  end

  private
    def disable_animations
      page.execute_script(DISABLE_ANIMATIONS_JS)
    rescue StandardError
      nil
    end
end
