# frozen_string_literal: true

# Infrastructure for native Playwright specs (no Capybara DSL).
#
# Usage: tag specs with `driver: :playwright` to get a fresh BrowserContext
# per test with `@playwright_page` available.
#
# Example:
#   describe "Login flow", driver: :playwright do
#     it "signs in" do
#       page = @playwright_page
#       page.goto("/login")
#       page.get_by_label("Email").fill("user@example.com")
#       page.get_by_label("Password").fill("secret")
#       page.get_by_role("button", name: "Log in").click
#       expect(page.get_by_text("Dashboard")).to be_visible
#     end
#   end
#
# Benefits over Capybara DSL:
# - Native Playwright auto-waiting (no more sleep/wait_for_ajax)
# - get_by_role, get_by_label, get_by_text selectors
# - Built-in assertions (to_be_visible, to_have_text, etc.)
# - No stale element errors
# - Screenshot/video recording per-test
# - Network interception via page.route

require "capybara"
require "playwright"
require "playwright/test"

# Null driver: tells Capybara to boot the Rails server without
# actually providing a browser — we manage that ourselves via Playwright.
class CapybaraNullDriver < Capybara::Driver::Base
  def needs_server?
    true
  end
end

Capybara.register_driver(:playwright_null) { CapybaraNullDriver.new }

# Shared browser singleton — launched once per suite, one BrowserContext per test.
module PlaywrightTestBrowser
  class << self
    attr_reader :browser, :playwright_instance

    def start!
      @fiber = Fiber.new do
        Playwright.create(playwright_cli_executable_path: playwright_cli_path) do |playwright|
          @playwright_instance = playwright
          browser = playwright.chromium.launch(
            headless: ENV["HEADLESS"] != "false",
            args: [
              "--disable-gpu",
              "--no-sandbox",
              "--disable-setuid-sandbox",
              "--disable-dev-shm-usage",
            ],
          )
          Fiber.yield(browser)
          browser.close
        end
      end
      @browser = @fiber.resume
    end

    def stop!
      @fiber&.resume
    end

    private

    def playwright_cli_path
      local = File.join(Dir.pwd, "node_modules", ".bin", "playwright")
      File.exist?(local) ? local : "playwright"
    end
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    PlaywrightTestBrowser.start!
  end

  config.after(:suite) do
    PlaywrightTestBrowser.stop!
  end

  config.around(:each, driver: :playwright) do |example|
    Capybara.current_driver = :playwright_null

    # Boot the Rails test server and get its URL
    base_url = Capybara.current_session.server.base_url

    PlaywrightTestBrowser.browser.new_context(
      baseURL: base_url,
      viewport: { width: 1440, height: 900 },
      ignoreHTTPSErrors: true,
      locale: "en-US",
    ) do |context|
      @playwright_page = context.new_page
      @playwright_context = context
      example.run
    end
  end
end

# Helper module included in playwright-driver specs
module PlaywrightHelpers
  # Sign in by posting to the Devise session endpoint directly,
  # then transferring the session cookie to the Playwright browser.
  def playwright_login_as(user, page: @playwright_page)
    # Use Warden's test helper to set the cookie via a direct request
    base_url = Capybara.current_session.server.base_url

    # Navigate to a lightweight page first to establish the domain
    page.goto("/")

    # Post login credentials via Playwright
    page.goto("/login")
    page.get_by_label("Email").fill(user.email)
    page.get_by_label("Password").fill(user.password || "password")
    page.get_by_role("button", name: "Log in").click

    # Wait for redirect to complete
    page.wait_for_url("**/")
  end

  # Assert text is visible on the page (with auto-wait)
  def expect_text(text, page: @playwright_page)
    expect(page.get_by_text(text)).to be_visible
  end

  # Assert text is NOT visible
  def expect_no_text(text, page: @playwright_page)
    expect(page.get_by_text(text)).not_to be_visible
  end

  # Take a screenshot on failure
  def save_playwright_screenshot(name)
    path = Rails.root.join("tmp", "screenshots", "#{name}.png")
    FileUtils.mkdir_p(File.dirname(path))
    @playwright_page&.screenshot(path: path.to_s)
    path
  end
end

RSpec.configure do |config|
  config.include PlaywrightHelpers, driver: :playwright
  config.include Playwright::Test::Matchers, driver: :playwright

  # Auto-screenshot on failure
  config.after(:each, driver: :playwright) do |example|
    if example.exception && @playwright_page
      name = example.full_description.parameterize.truncate(200)
      path = save_playwright_screenshot(name)
      example.metadata[:playwright_screenshot] = path.to_s
    end
  end
end
