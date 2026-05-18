# frozen_string_literal: true

# Used for OpenGraph consumers like: https://developer.twitter.com/en/docs/twitter-for-websites/cards/overview/summary-card-with-large-image
class SubscribePreviewGeneratorService
  RETINA_PIXEL_RATIO = 2
  ASPECT_RATIO = 128/67r
  WIDTH = 512
  HEIGHT = (WIDTH / ASPECT_RATIO).to_i
  BROWSER_OPTIONS = {
    "force-device-scale-factor" => RETINA_PIXEL_RATIO.to_s,
    "headless" => "new",
    "no-sandbox" => nil,
    "disable-setuid-sandbox" => nil,
    "disable-dev-shm-usage" => nil,
    "user-data-dir" => "/tmp/chrome",
  }.freeze
  SCREENSHOT_AREA = { x: 0, y: 0, width: WIDTH, height: HEIGHT }.freeze

  def self.generate_pngs(users)
    browser = Ferrum::Browser.new(
      browser_options: BROWSER_OPTIONS,
      headless: false,
      window_size: [WIDTH, HEIGHT],
      process_timeout: 30,
      timeout: 10,
    )
    users.map do |user|
      url = Rails.application.routes.url_helpers.user_subscribe_preview_url(
        user.username,
        host: DOMAIN,
        protocol: PROTOCOL,
      )
      browser.goto(url)
      browser.screenshot(format: "png", encoding: :binary, area: SCREENSHOT_AREA.dup)
    end
  ensure
    browser&.quit
  end
end
