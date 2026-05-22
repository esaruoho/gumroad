# frozen_string_literal: true

class JSErrorReporter
  def initialize
    @_ignored_js_errors = []
  end

  @instance = new
  @global_patterns = []

  class << self
    attr_reader :instance, :global_patterns
    attr_writer :enabled

    def set_global_ignores(array_of_patterns)
      @global_patterns = array_of_patterns
    end

    def enabled?
      @enabled.nil? ? ENV["ENABLE_RAISE_JS_ERROR"] == "1" : @enabled
    end
  end

  # ignore, once, an error matching the pattern (exact string or regex)
  def add_ignore_error(string_or_regex)
    @_ignored_js_errors ||= []
    @_ignored_js_errors << string_or_regex
  end

  def report_errors!(ctx)
    errors_to_log = read_errors!(ctx.page.driver)
    ctx.aggregate_failures "javascript errors" do
      errors_to_log.each do |error|
        ctx.expect(error).to ctx.eq ""
      end
    end
  end

  def reset!
    @_ignored_js_errors = []
  end

  def read_errors!(driver)
    return [] unless self.class.enabled?

    errors = collect_js_errors(driver)
    errors.reject { |error| error.blank? || should_ignore_error?(error) }
  end

  # Inject the JS error collector into a Playwright page.
  # Call this after each new page/context is created.
  def self.install_playwright_collector!(playwright_page)
    playwright_page.add_init_script(script: <<~JS)
      window.__gumroad_js_errors = window.__gumroad_js_errors || [];
      window.addEventListener('error', (e) => {
        const msg = e.error
          ? `Error: ${e.error.message}\\n\\tat ${e.filename}:${e.lineno}:${e.colno}`
          : `Error: ${e.message}\\n\\tat ${e.filename}:${e.lineno}:${e.colno}`;
        window.__gumroad_js_errors.push(msg);
      });
      window.addEventListener('unhandledrejection', (e) => {
        const reason = e.reason;
        const msg = reason instanceof Error
          ? `Error: ${reason.message}`
          : `Error: ${String(reason)}`;
        window.__gumroad_js_errors.push(msg);
      });
      const origError = console.error;
      console.error = function(...args) {
        const msg = args.map(a => typeof a === 'object' ? JSON.stringify(a) : String(a)).join(', ');
        window.__gumroad_js_errors.push(`Console error: ${msg}`);
        origError.apply(console, args);
      };
    JS
  end

  private
    def collect_js_errors(driver)
      begin
        if driver.respond_to?(:with_playwright_page)
          driver.with_playwright_page do |playwright_page|
            result = playwright_page.evaluate(<<~JS)
              (() => {
                const errors = window.__gumroad_js_errors || [];
                window.__gumroad_js_errors = [];
                return errors;
              })()
            JS
            Array(result)
          end
        elsif driver.respond_to?(:browser) && driver.browser.respond_to?(:logs)
          # Selenium WebDriver (used in JSErrorReporter spec and production screenshot services)
          begin
            logs = driver.browser.logs.get(:driver)
            parse_selenium_logs(logs)
          rescue => e
            puts e.inspect
            []
          end
        else
          # Raw Selenium::WebDriver::Driver passed directly (from spec)
          begin
            logs = driver.manage.logs.get(:driver)
            parse_selenium_logs(logs)
          rescue => e
            puts e.inspect
            []
          end
        end
      rescue => e
        puts "[JSErrorReporter] #{e.class}: #{e.message}" if ENV["DEBUG"]
        []
      end
    end

    def parse_selenium_logs(logs)
      logs.filter_map do |log|
        if log.message.start_with?("DevTools WebSocket Event: Runtime.exceptionThrown")
          error = JSON.parse(log.message[log.message.index("{")..])["exceptionDetails"]
          message = error["exception"]["preview"] ? error["exception"]["preview"]["properties"].find { |prop| prop["name"] == "message" }["value"] : error["exception"]["value"]
          next "Error: #{message}\n\tat #{error["url"]}:#{error["lineNumber"]}:#{error["columnNumber"]}" unless error["stackTrace"]
          trace = format_stack_trace(error["stackTrace"])
          "Error: #{message}\n#{trace}"
        elsif log.message.start_with?("DevTools WebSocket Event: Runtime.consoleAPICalled")
          log_data = JSON.parse(log.message[log.message.index("{")..])
          next unless log_data["type"] == "error"
          trace = format_stack_trace(log_data["stackTrace"])
          message = log_data["args"].map do |arg|
            parsed = format_object(arg)
            if parsed.is_a?(Hash) || parsed.is_a?(Array)
              parsed.to_json
            else
              parsed
            end
          end.join(", ")
          if trace.present?
            "Console error: #{message}\n#{trace}"
          else
            "Console error: #{message}"
          end
        end
      end
    end

    def format_object(obj)
      if obj["type"] == "object" && obj["preview"] && (obj["className"] == "Object" || obj["subtype"] == "array")
        if obj["preview"]["properties"]
          if obj["className"] == "Object"
            obj["preview"]["properties"].reduce({}) do |acc, prop|
              acc[prop["name"]] = format_object(prop)
              acc
            end
          else
            obj["preview"]["properties"].map { |prop| format_object(prop) }
          end
        else
          obj["preview"]["description"]
        end
      else
        if obj["subtype"] == "null"
          nil
        elsif obj["type"] == "boolean"
          obj["value"] == "true"
        elsif obj["type"] == "number"
          if obj["value"].is_a?(String)
            if obj["value"].include?(".")
              obj["value"].to_f
            else
              obj["value"].to_i
            end
          else
            obj["value"]
          end
        else
          obj["value"] || obj["description"]
        end
      end
    end

    def format_stack_trace(stackTrace)
      return nil if stackTrace.empty?

      stackTrace["callFrames"].filter_map do |frame|
        next if !frame["functionName"] && !frame["url"]

        "\t#{frame["functionName"]} (#{frame["url"]}:#{frame["lineNumber"]}:#{frame["columnNumber"]})"
      end.join("\n")
    end

    def should_ignore_error?(error_message)
      should_ignore_based_on_global_pattern?(error_message) || should_ignore_based_on_one_off_pattern?(error_message)
    end

    def should_ignore_based_on_global_pattern?(error_message)
      self.class.global_patterns.any? { |p| error_matches_pattern?(error_message, p) }
    end

    def should_ignore_based_on_one_off_pattern?(error_message)
      @_ignored_js_errors.any? { |p| error_matches_pattern?(error_message, p) }
    end

    def error_matches_pattern?(error_message, pattern)
      pattern.is_a?(String) ? pattern == error_message : pattern.match(error_message)
    end
end
