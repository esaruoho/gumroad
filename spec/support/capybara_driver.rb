# frozen_string_literal: true

require "capybara/cuprite"

# ── Shared browser options ────────────────────────────────────────────
# Chrome 125's old --headless mode doesn't output the DevTools WebSocket URL
# that Ferrum needs to connect. We must use --headless=new (Chrome's new headless
# mode) which properly supports CDP remote debugging.
#
# Since Ferrum 0.17 only adds --headless (no =new), we set headless: false
# to prevent Ferrum from adding the flag, then add it ourselves via browser_options.
CUPRITE_BROWSER_OPTIONS = {
  "headless" => "new",
  "no-sandbox" => nil,
  "disable-setuid-sandbox" => nil,
  "disable-dev-shm-usage" => nil,
  "disable-popup-blocking" => nil,
  "disable-site-isolation-trials" => nil,
  "disable-gpu" => nil,
}.freeze

DOCKER_ENV = ENV["IN_DOCKER"] == "true"

CUPRITE_COMMON_OPTS = {
  browser_options: CUPRITE_BROWSER_OPTIONS,
  process_timeout: DOCKER_ENV ? 60 : 30,
  timeout: DOCKER_ENV ? 30 : 15,
  js_errors: true,
  headless: false, # We handle headless via browser_options above (--headless=new)
  inspector: !ENV["CI"],
}.tap do |opts|
  if DOCKER_ENV
    chrome = %w[google-chrome google-chrome-stable chromium chromium-browser chrome].find { |c| system("which #{c} > /dev/null 2>&1") }
    opts[:browser_path] = `which #{chrome}`.strip if chrome
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

# ── Billy proxy integration ──────────────────────────────────────────
Capybara.register_driver :cuprite_billy do |app|
  billy_opts = CUPRITE_BROWSER_OPTIONS.merge(
    "ignore-certificate-errors" => nil,
    "proxy-server" => "#{Billy.proxy.host}:#{Billy.proxy.port}",
  )
  Capybara::Cuprite::Driver.new(app,
    window_size: [1440, 900],
    browser_options: billy_opts,
    process_timeout: 30,
    timeout: 15,
    js_errors: true,
    headless: false)
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

  config.before(:each, billy: true) do |_example|
    driven_by :cuprite_billy
  end

  config.before(:each, :tablet_view) do |_example|
    driven_by :cuprite_tablet
  end

  # Filter Cuprite/Ferrum internals from backtraces
  config.filter_gems_from_backtrace("capybara", "cuprite", "ferrum")
end
