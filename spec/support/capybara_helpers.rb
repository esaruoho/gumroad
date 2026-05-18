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
    page.visit(remote_chrome_url(url))
    return if Capybara.current_driver == :rack_test
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop do
        break if page.evaluate_script("document.readyState") == "complete"
        sleep 0.05
      end
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
    page.accept_modal
  rescue Capybara::ModalNotFound
    sleep 0.5
    page.accept_modal
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

  # Rewrites OAuth popup URLs to local callback URLs. Replaces Puffing Billy's
  # proxy.stub() for OAuth redirect testing without binding a CDP network
  # interceptor to only one browser target.
  #
  # Usage:
  #   stub_external_redirect("https://www.discord.com:443/api/oauth2/authorize",
  #                          redirect_to: oauth_redirect_url(code: "test_code"))
  #   visit(page_url)
  #   click_on "Connect to Discord"  # popup opens the local redirect URL
  def stub_external_redirect(url, redirect_to:)
    @external_redirects ||= {}
    @external_redirects[normalize_external_redirect_url(url)] = redirect_to
    install_external_redirect_script
  end

  def clear_external_redirects
    Array(@external_redirect_script_ids).each do |identifier|
      page.driver.browser.page.command("Page.removeScriptToEvaluateOnNewDocument", identifier:)
    rescue StandardError
      nil
    end
    @external_redirects = nil
    @external_redirect_script_ids = nil
    @external_redirect_script_fingerprint = nil
  end

  def with_throttled_network(fixture_file, factor: 4)
    throughput = (File.size(fixture_file) * factor)
    page.driver.browser.network.emulate_network_conditions(
      offline: false, latency: 0,
      download_throughput: throughput, upload_throughput: throughput
    )
    yield
    page.driver.browser.network.emulate_network_conditions(
      offline: false, latency: 0,
      download_throughput: -1, upload_throughput: -1
    )
  end

  private
    def disable_animations
      page.execute_script(DISABLE_ANIMATIONS_JS)
    rescue StandardError
      nil
    end

    def remote_chrome_url(url)
      return url unless defined?(REMOTE_CHROME) && REMOTE_CHROME
      return url unless url.is_a?(String)

      parsed_url = URI.parse(url)
      return url unless parsed_url.absolute? && gumroad_test_host?(parsed_url.host)

      parsed_url.host = ENV.fetch("APP_HOST", "127.0.0.1")
      parsed_url.port = Capybara.server_port
      parsed_url.to_s
    rescue URI::InvalidURIError
      url
    end

    def gumroad_test_host?(host)
      return false if host.blank?

      root_domain = URI.parse("#{PROTOCOL}://#{ROOT_DOMAIN}").host
      host == URI.parse(Capybara.app_host).host || host == root_domain || host.end_with?(".#{root_domain}")
    end

    def install_external_redirect_script
      redirects = @external_redirects.to_a
      fingerprint = redirects.to_json
      return if @external_redirect_script_fingerprint == fingerprint

      Array(@external_redirect_script_ids).each do |identifier|
        page.driver.browser.page.command("Page.removeScriptToEvaluateOnNewDocument", identifier:)
      rescue StandardError
        nil
      end
      @external_redirect_script_ids = []

      script = <<~JS
        (() => {
          window.__externalRedirects = #{fingerprint};
          window.__originalOpen = window.__originalOpen || window.open;
          window.open = function(url, target, features) {
            const normalizeUrl = (value) => {
              try {
                const parsed = new URL(value, window.location.href);
                if (parsed.protocol === "https:" && parsed.port === "443") parsed.port = "";
                return parsed.href;
              } catch {
                return String(value).replace(":443", "");
              }
            };
            const normalizedUrl = normalizeUrl(url);
            const redirect = window.__externalRedirects.find(([pattern]) => normalizedUrl.startsWith(pattern));
            return window.__originalOpen.call(window, redirect ? redirect[1] : url, target, features);
          };
        })();
      JS

      result = page.driver.browser.page.command("Page.addScriptToEvaluateOnNewDocument", source: script)
      @external_redirect_script_ids ||= []
      @external_redirect_script_ids << result.fetch("identifier")
      @external_redirect_script_fingerprint = fingerprint
      begin
        page.execute_script(script)
      rescue StandardError
        nil
      end
    end

    def normalize_external_redirect_url(url)
      url.gsub(":443", "")
    end
end
