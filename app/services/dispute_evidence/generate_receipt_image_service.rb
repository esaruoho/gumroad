# frozen_string_literal: true

class DisputeEvidence::GenerateReceiptImageService
  def self.perform(purchase)
    new(purchase).perform
  end

  def initialize(purchase)
    @purchase = purchase
  end

  def perform
    binary_data = generate_screenshot

    unless binary_data
      ErrorNotifier.notify("DisputeEvidence::GenerateRefundPolicyImageService: Could not generate screenshot for purchase ID #{purchase.id}")
      return
    end

    optimize_image(binary_data)
  end

  private
    BROWSER_OPTIONS = {
      "headless" => nil,
      "no-sandbox" => nil,
      "disable-setuid-sandbox" => nil,
      "disable-dev-shm-usage" => nil,
      "user-data-dir" => "/tmp/chrome",
      "disable-scrollbars" => nil,
    }.freeze

    BREAKPOINT_LG = 1024

    IMAGE_RESIZE_FACTOR = 2
    IMAGE_QUALITY = 80

    attr_reader :purchase
    attr_accessor :width

    def generate_screenshot
      browser = Ferrum::Browser.new(
        browser_options: BROWSER_OPTIONS,
        window_size: [BREAKPOINT_LG, BREAKPOINT_LG],
        process_timeout: 30,
        timeout: 10,
      )

      html = generate_html(purchase)
      encoded_content = Addressable::URI.encode_component(html, Addressable::URI::CharacterClasses::QUERY)

      browser.goto("data:text/html;charset=UTF-8,#{encoded_content}")
      browser.network.wait_for_idle

      # Use a fixed width in order to have a consistent way to determine if is a retina display screenshot
      @width = BREAKPOINT_LG
      height = [browser.evaluate(js_max_height_dimension).to_i, 1].max

      browser.resize(width: width, height: height)
      browser.screenshot(format: "png", encoding: :binary)
    ensure
      browser&.quit
    end

    def js_max_height_dimension
      %{
        Math.max(
          document.body.scrollHeight,
          document.body.offsetHeight,
          document.documentElement.clientHeight,
          document.documentElement.scrollHeight,
          document.documentElement.offsetHeight
        )
      }
    end

    def generate_html(purchase)
      mail = CustomerMailer.receipt(purchase.id)
      mail_body = Nokogiri::HTML.parse(mail.body.raw_source)
      mail_info = %{
        <div style="padding: 20px 20px">
          <p><strong>Email receipt sent at:</strong> #{purchase.created_at}</p>
          <p><strong>From:</strong> #{mail.from.first}</p>
          <p><strong>To:</strong> #{mail.to.first}</p>
          <p><strong>Subject:</strong> #{mail.subject}</p>
        </div>
        <hr>
      }
      mail_body.at("body").prepend_child Nokogiri::HTML::DocumentFragment.parse(mail_info)
      mail_body.to_html
    end

    def optimize_image(binary_data)
      image = MiniMagick::Image.read(binary_data)
      image.resize("#{image.width / IMAGE_RESIZE_FACTOR}x") if retina_display_screenshot?(image)
      image.format("jpg").quality(IMAGE_QUALITY).strip
      image.to_blob
    end

    def retina_display_screenshot?(image)
      image.width == width * IMAGE_RESIZE_FACTOR
    end
end
