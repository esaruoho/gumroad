# frozen_string_literal: true

require "capybara/cuprite"

# ── Remote Chrome detection ──────────────────────────────────────────
# In Docker/CI, Chrome runs as a separate service (browserless/chrome)
# accessible via CHROME_URL. Locally, Cuprite launches Chrome directly.
# We trust the env var — no Socket probe, since DNS may not resolve yet
# when this file loads during bundle exec startup.
REMOTE_CHROME_URL = ENV["CHROME_URL"]
REMOTE_CHROME = !REMOTE_CHROME_URL.nil? && !REMOTE_CHROME_URL.empty?
REMOTE_CHROME_HOST =
  if REMOTE_CHROME
    require "uri"
    URI.parse(REMOTE_CHROME_URL).host
  end

# ── Shared driver options ────────────────────────────────────────────
CUPRITE_COMMON_OPTS = {
  process_timeout: REMOTE_CHROME ? 30 : 30,
  timeout: REMOTE_CHROME ? 30 : 15,
  js_errors: true,
  inspector: !ENV["CI"],
}.tap do |opts|
  if REMOTE_CHROME
    # Connect to remote Chrome service — no local browser launch needed.
    # browserless/chrome handles its own headless mode.
    opts[:url] = REMOTE_CHROME_URL
    opts[:browser_options] = { "no-sandbox" => nil }
  else
    # Local development — launch Chrome directly.
    # Chrome 125's old --headless doesn't output DevTools WS URL.
    # Set headless: false to suppress Ferrum's --headless flag,
    # then add --headless=new ourselves via browser_options.
    opts[:headless] = false
    opts[:browser_options] = {
      "headless" => "new",
      "no-sandbox" => nil,
      "disable-setuid-sandbox" => nil,
      "disable-dev-shm-usage" => nil,
      "disable-popup-blocking" => nil,
      "disable-site-isolation-trials" => nil,
      "disable-gpu" => nil,
    }
  end
end.freeze

# ── Desktop (1440×900) ───────────────────────────────────────────────
Capybara.register_driver :cuprite do |app|
  Capybara::Cuprite::Driver.new(app, **CUPRITE_COMMON_OPTS, window_size: [1440, 900])
end

# ── Tablet (800×1024) ────────────────────────────────────────────────
Capybara.register_driver :cuprite_tablet do |app|
  Capybara::Cuprite::Driver.new(app, **CUPRITE_COMMON_OPTS, window_size: [800, 1024])
end

# ── Mobile (375×667, iPhone 8 equiv) ─────────────────────────────────
Capybara.register_driver :cuprite_mobile do |app|
  Capybara::Cuprite::Driver.new(app, **CUPRITE_COMMON_OPTS, window_size: [375, 667])
end

# ── Capybara server config for remote Chrome ─────────────────────────
# When Chrome runs in a separate container, it needs to reach the test
# server. Bind to 0.0.0.0 and set app_host to the container hostname.
if REMOTE_CHROME
  Capybara.server_host = "0.0.0.0"
  Capybara.app_host = "http://#{ENV.fetch('APP_HOST', `hostname`.strip&.downcase || '0.0.0.0')}"
end

# ── RSpec hooks ──────────────────────────────────────────────────────
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :cuprite
  end

  config.before(:each, :mobile_view) do |_example|
    driven_by :cuprite_mobile
  end

  config.before(:each, :tablet_view) do |_example|
    driven_by :cuprite_tablet
  end

  # Filter Cuprite/Ferrum internals from backtraces
  config.filter_gems_from_backtrace("capybara", "cuprite", "ferrum")

  # Reset network intercept state between examples (set by stub_external_redirect)
  config.after(:each, type: :system, js: true) do
    @external_redirects = nil
    @intercept_active = nil
  end
end
