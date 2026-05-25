# frozen_string_literal: true

webdriver_client = Selenium::WebDriver::Remote::Http::Default.new(open_timeout: 120, read_timeout: 120)

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_emulation(device_metrics: { width: 1440, height: 900, touch: false })
  options.add_preference("intl.accept_languages", "en-US")
  options.logging_prefs = { driver: "DEBUG" }

  # Headless when running in CI (non-Docker runner with no display).
  if ENV["CI"] == "true"
    options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-gpu")
    options.add_argument("--window-size=1440,900")
  end

  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 http_client: webdriver_client,
                                 options:)
end

Capybara.register_driver :tablet_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_emulation(device_metrics: { width: 800, height: 1024, touch: true })
  options.add_preference("intl.accept_languages", "en-US")
  options.logging_prefs = { driver: "DEBUG" }

  if ENV["CI"] == "true"
    options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-gpu")
    options.add_argument("--window-size=800,1024")
  end

  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 http_client: webdriver_client,
                                 options:)
end

Capybara.register_driver :mobile_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_emulation(device_name: "iPhone 8")
  options.add_preference("intl.accept_languages", "en-US")
  options.logging_prefs = { driver: "DEBUG" }

  if ENV["CI"] == "true"
    options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-gpu")
  end

  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 http_client: webdriver_client,
                                 options:)
end

def docker_browser_args
  args = [
    "--headless",
    "--no-sandbox",
    "--start-maximized",
    "--disable-setuid-sandbox",
    "--disable-dev-shm-usage",
    "--disable-popup-blocking",
    "--user-data-dir=/tmp/chrome",
    # Workaround https://bugs.chromium.org/p/chromedriver/issues/detail?id=2650&q=load&sort=-id&colspec=ID%20Status%20Pri%20Owner%20Summary
    "--disable-site-isolation-trials",
  ]
  args << "--disable-gpu" if Gem.win_platform?

  args
end

Capybara.register_driver :docker_headless_chrome do |app|
  Capybara::Selenium::Driver.load_selenium
  options = ::Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    docker_browser_args.each { |arg| opts.args << arg }
    opts.args << "--window-size=1440,900"
  end
  options.add_preference("intl.accept_languages", "en-US")
  options.logging_prefs = { driver: "DEBUG" }

  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 http_client: webdriver_client,
                                 options:)
end

Capybara.register_driver :selenium_chrome_headless_billy_custom do |app|
  Capybara::Selenium::Driver.load_selenium
  options = ::Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    docker_browser_args.each { |arg| opts.args << arg }
    opts.args << "--enable-features=NetworkService,NetworkServiceInProcess"
    opts.args << "--ignore-certificate-errors"
    opts.args << "--proxy-server=#{Billy.proxy.host}:#{Billy.proxy.port}"
    opts.args << "--window-size=1440,900"
  end
  options.add_preference("intl.accept_languages", "en-US")
  options.logging_prefs = { driver: "DEBUG" }

  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 http_client: webdriver_client,
                                 options:)
end

Capybara.register_driver :selenium_chrome_billy_headless do |app|
  Capybara::Selenium::Driver.load_selenium
  options = ::Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--disable-gpu")
  options.add_argument("--enable-features=NetworkService,NetworkServiceInProcess")
  options.add_argument("--ignore-certificate-errors")
  options.add_argument("--proxy-server=#{Billy.proxy.host}:#{Billy.proxy.port}")
  options.add_argument("--window-size=1440,900")
  options.add_preference("intl.accept_languages", "en-US")
  options.logging_prefs = { driver: "DEBUG" }

  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 http_client: webdriver_client,
                                 options:)
end

Capybara.register_driver :docker_headless_tablet_chrome do |app|
  Capybara::Selenium::Driver.load_selenium
  options = ::Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    docker_browser_args.each { |arg| opts.args << arg }
    opts.args << "--window-size=800,1024"
  end
  options.add_preference("intl.accept_languages", "en-US")
  options.logging_prefs = { driver: "DEBUG" }

  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 http_client: webdriver_client,
                                 options:)
end

Capybara.register_driver :docker_headless_mobile_chrome do |app|
  Capybara::Selenium::Driver.load_selenium
  options = ::Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    docker_browser_args.each { |arg| opts.args << arg }
  end
  options.add_preference("intl.accept_languages", "en-US")
  options.logging_prefs = { driver: "DEBUG" }

  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 http_client: webdriver_client,
                                 options:)
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by ENV["IN_DOCKER"] == "true" ? :docker_headless_chrome : :chrome
  end

  config.before(:each, :mobile_view) do |example|
    driven_by ENV["IN_DOCKER"] == "true" ? :docker_headless_mobile_chrome : :mobile_chrome
  end

  config.before(:each, billy: true) do |example|
    billy_driver = if ENV["IN_DOCKER"] == "true"
      :selenium_chrome_headless_billy_custom
    elsif ENV["CI"] == "true"
      :selenium_chrome_billy_headless
    else
      :selenium_chrome_billy
    end
    driven_by billy_driver
  end

  config.before(:each, :tablet_view) do |example|
    driven_by ENV["IN_DOCKER"] == "true" ? :docker_headless_tablet_chrome : :tablet_chrome
  end
end
