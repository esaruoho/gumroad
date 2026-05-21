# frozen_string_literal: true

require "capybara/playwright"

# ── Shared options ──────────────────────────────────────────────────
PLAYWRIGHT_HEADLESS = ENV["HEADLESS"] != "false"

PLAYWRIGHT_LAUNCH_OPTS = {
  channel: "chrome",
  args: [
    "--disable-gpu",
    "--no-sandbox",
    "--disable-setuid-sandbox",
    "--disable-dev-shm-usage",
    "--disable-popup-blocking",
    "--disable-site-isolation-trials",
  ],
}.freeze

# ── Desktop (1440×900) ──────────────────────────────────────────────
Capybara.register_driver :playwright do |app|
  Capybara::Playwright::Driver.new(app,
    browser_type: :chromium,
    headless: PLAYWRIGHT_HEADLESS,
    launch_options: PLAYWRIGHT_LAUNCH_OPTS,
    browser_context_options: {
      viewport: { width: 1440, height: 900 },
      ignoreHTTPSErrors: true,
      locale: "en-US",
    },
  )
end

# ── Tablet (800×1024) ───────────────────────────────────────────────
Capybara.register_driver :playwright_tablet do |app|
  Capybara::Playwright::Driver.new(app,
    browser_type: :chromium,
    headless: PLAYWRIGHT_HEADLESS,
    launch_options: PLAYWRIGHT_LAUNCH_OPTS,
    browser_context_options: {
      viewport: { width: 800, height: 1024 },
      ignoreHTTPSErrors: true,
      locale: "en-US",
      hasTouch: true,
    },
  )
end

# ── Mobile (375×667, iPhone 8 equiv) ────────────────────────────────
Capybara.register_driver :playwright_mobile do |app|
  Capybara::Playwright::Driver.new(app,
    browser_type: :chromium,
    headless: PLAYWRIGHT_HEADLESS,
    launch_options: PLAYWRIGHT_LAUNCH_OPTS,
    browser_context_options: {
      viewport: { width: 375, height: 667 },
      ignoreHTTPSErrors: true,
      locale: "en-US",
      isMobile: true,
      hasTouch: true,
    },
  )
end

# ── Billy proxy driver (for external redirect interception) ─────────
Capybara.register_driver :playwright_billy do |app|
  Capybara::Playwright::Driver.new(app,
    browser_type: :chromium,
    headless: PLAYWRIGHT_HEADLESS,
    launch_options: PLAYWRIGHT_LAUNCH_OPTS.merge(
      proxy: {
        server: "#{Billy.proxy.host}:#{Billy.proxy.port}",
      },
    ),
    browser_context_options: {
      viewport: { width: 1440, height: 900 },
      ignoreHTTPSErrors: true,
      locale: "en-US",
    },
  )
end

# ── RSpec hooks ──────────────────────────────────────────────────────
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :playwright
  end

  config.before(:each, :mobile_view) do |_example|
    driven_by :playwright_mobile
  end

  config.before(:each, billy: true) do |_example|
    driven_by :playwright_billy
  end

  config.before(:each, :tablet_view) do |_example|
    driven_by :playwright_tablet
  end

  # Filter Playwright internals from backtraces
  config.filter_gems_from_backtrace("capybara", "playwright", "capybara-playwright-driver")

  config.after(:each, type: :system, js: true) do
    clear_external_redirects if respond_to?(:clear_external_redirects)
  end
end
