# frozen_string_literal: true

require "capybara/cuprite"

# ── Shared browser options ────────────────────────────────────────────
CUPRITE_BROWSER_OPTIONS = {
  "no-sandbox" => nil,
  "disable-setuid-sandbox" => nil,
  "disable-dev-shm-usage" => nil,
  "disable-popup-blocking" => nil,
  "disable-site-isolation-trials" => nil,
  "disable-gpu" => nil,
  "user-data-dir" => "/tmp/chrome",
}.freeze

DOCKER_ENV = ENV["IN_DOCKER"] == "true"

# ── Desktop (1440×900) ───────────────────────────────────────────────
Capybara.register_driver :cuprite do |app|
  Capybara::Cuprite::Driver.new(app,
    window_size: [1440, 900],
    browser_options: CUPRITE_BROWSER_OPTIONS,
    process_timeout: DOCKER_ENV ? 60 : 30,
    timeout: DOCKER_ENV ? 30 : 15,
    js_errors: true,
    headless: DOCKER_ENV || %w[0 false no].exclude?(ENV.fetch("HEADLESS", "true")),
    inspector: !ENV["CI"])
end

# ── Tablet (800×1024) ────────────────────────────────────────────────
Capybara.register_driver :cuprite_tablet do |app|
  Capybara::Cuprite::Driver.new(app,
    window_size: [800, 1024],
    browser_options: CUPRITE_BROWSER_OPTIONS,
    process_timeout: DOCKER_ENV ? 60 : 30,
    timeout: DOCKER_ENV ? 30 : 15,
    js_errors: true,
    headless: DOCKER_ENV || %w[0 false no].exclude?(ENV.fetch("HEADLESS", "true")),
    inspector: !ENV["CI"])
end

# ── Mobile (375×667, iPhone 8 equiv) ─────────────────────────────────
Capybara.register_driver :cuprite_mobile do |app|
  Capybara::Cuprite::Driver.new(app,
    window_size: [375, 667],
    browser_options: CUPRITE_BROWSER_OPTIONS,
    process_timeout: DOCKER_ENV ? 60 : 30,
    timeout: DOCKER_ENV ? 30 : 15,
    js_errors: true,
    headless: DOCKER_ENV || %w[0 false no].exclude?(ENV.fetch("HEADLESS", "true")),
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
  # Debug: verify Chrome is available on first JS system test
  config.before(:suite) do
    if DOCKER_ENV
      chrome_path = %w[chrome google-chrome google-chrome-stable chromium chromium-browser].find { |cmd| system("which #{cmd} > /dev/null 2>&1") }
      if chrome_path
        version = `#{chrome_path} --version 2>&1`.strip
        $stderr.puts "[cuprite] Chrome found: #{chrome_path} → #{version}"
      else
        $stderr.puts "[cuprite] WARNING: No Chrome binary found on PATH!"
        $stderr.puts "[cuprite] PATH=#{ENV['PATH']}"
        $stderr.puts "[cuprite] ls /usr/bin/google*: #{`ls /usr/bin/google* 2>&1`.strip}"
        $stderr.puts "[cuprite] ls /opt/google/: #{`ls -la /opt/google/ 2>&1`.strip}"
      end
    end
  end

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
