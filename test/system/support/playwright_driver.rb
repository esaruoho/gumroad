# frozen_string_literal: true

# Single Playwright process + single browser per test process. Each test gets
# its own context (fresh cookies, storage) and page. Keep this as the only
# place that touches Playwright; tests use the helpers on SystemTestCase.
module SystemTests
  class PlaywrightDriver
    HEADLESS = ENV.fetch("HEADED", "false") != "true"
    SLOW_MO_MS = ENV.fetch("SLOWMO", "0").to_i
    VIEWPORT = { width: 1280, height: 800 }.freeze
    DEFAULT_TIMEOUT_MS = ENV.fetch("PLAYWRIGHT_TIMEOUT_MS", "30000").to_i
    # Navigation gets its own (larger) budget. Even with Vite assets prebuilt
    # in CI, first-hit cold caches and Rails boot can push page.goto past the
    # default 10s. Keep the action timeout tighter so flaky selectors fail fast.
    DEFAULT_NAVIGATION_TIMEOUT_MS = ENV.fetch("PLAYWRIGHT_NAV_TIMEOUT_MS", "120000").to_i

    class << self
      def browser
        boot
        @browser
      end

      def new_context(**options)
        browser.new_context(viewport: VIEWPORT, **options)
      end

      def boot
        @boot ||= begin
          # Hold the Execution object (`@playwright_execution`) separately from
          # the API root (`@playwright`). `.stop` is implemented on the
          # Execution; calling it on the API root raises NotImplementedError.
          @playwright_execution = Playwright.create(playwright_cli_executable_path: cli_path)
          @playwright = @playwright_execution.playwright
          @browser = @playwright.chromium.launch(headless: HEADLESS, slowMo: SLOW_MO_MS)
          at_exit { teardown }
          true
        end
      end

      private
        def teardown
          @browser&.close
          @playwright_execution&.stop
        end

        def cli_path
          # `npx playwright` resolves the version pinned in package.json; if the
          # repo gets its own playwright npm dep later we can pin it explicitly.
          ENV.fetch("PLAYWRIGHT_CLI", "npx playwright")
        end
    end
  end
end
