# frozen_string_literal: true

require "capybara/cuprite"

# ── Shared browser options ────────────────────────────────────────────
CUPRITE_BROWSER_OPTIONS = {
  "no-sandbox" => nil,
  "disable-dev-shm-usage" => nil,
  "disable-popup-blocking" => nil,
  "disable-site-isolation-trials" => nil,
}.freeze

# ── Desktop (1440×900) ───────────────────────────────────────────────
Capybara.register_driver :cuprite do |app|
  Capybara::Cuprite::Driver.new(app,
    window_size: [1440, 900],
    browser_options: CUPRITE_BROWSER_OPTIONS,
    process_timeout: 30,
    timeout: 15,
    js_errors: true,
    headless: %w[0 false no].exclude?(ENV.fetch("HEADLESS", "true")),
    inspector: !ENV["CI"])
end

# ── Tablet (800×1024) ────────────────────────────────────────────────
Capybara.register_driver :cuprite_tablet do |app|
  Capybara::Cuprite::Driver.new(app,
    window_size: [800, 1024],
    browser_options: CUPRITE_BROWSER_OPTIONS,
    process_timeout: 30,
    timeout: 15,
    js_errors: true,
    headless: %w[0 false no].exclude?(ENV.fetch("HEADLESS", "true")),
    inspector: !ENV["CI"])
end

# ── Mobile (375×667, iPhone 8 equiv) ─────────────────────────────────
Capybara.register_driver :cuprite_mobile do |app|
  Capybara::Cuprite::Driver.new(app,
    window_size: [375, 667],
    browser_options: CUPRITE_BROWSER_OPTIONS,
    process_timeout: 30,
    timeout: 15,
    js_errors: true,
    headless: %w[0 false no].exclude?(ENV.fetch("HEADLESS", "true")),
    inspector: !ENV["CI"])
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
    headless: true)
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
