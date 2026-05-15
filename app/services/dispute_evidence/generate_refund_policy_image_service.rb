# frozen_string_literal: true

class DisputeEvidence::GenerateRefundPolicyImageService
  class ImageTooLargeError < StandardError; end

  def self.perform(url:, mobile_purchase:, open_fine_print_modal:, max_size_allowed:)
    new(url, mobile_purchase:, open_fine_print_modal:, max_size_allowed:).perform
  end

  def initialize(url, mobile_purchase:, open_fine_print_modal:, max_size_allowed:)
    @url = url
    @open_fine_print_modal = open_fine_print_modal
    @max_size_allowed = max_size_allowed
    @width = mobile_purchase ? BREAKPOINT_SM : BREAKPOINT_LG
  end

  def perform
    binary_data = generate_screenshot
    unless binary_data
      ErrorNotifier.notify("DisputeEvidence::GenerateRefundPolicyImageService: Could not generate screenshot for url #{url}")
      return
    end

    optimized_binary_data = optimize_image(binary_data)
    image = MiniMagick::Image.read(binary_data)
    raise ImageTooLargeError if image.size > max_size_allowed

    optimized_binary_data
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

    # Should match $breakpoints definitions from app/javascript/stylesheets/_definitions.scss
    BREAKPOINT_SM = 640
    BREAKPOINT_LG = 1024

    IMAGE_RESIZE_FACTOR = 2
    IMAGE_QUALITY = 80
    ARTICLE_WAIT_TIMEOUT_SECONDS = 5

    attr_reader :url, :width, :open_fine_print_modal, :max_size_allowed

    def generate_screenshot
      browser = Ferrum::Browser.new(
        browser_options: BROWSER_OPTIONS,
        window_size: [width, width],
        process_timeout: 30,
        timeout: 10,
      )

      browser.goto(url)
      browser.network.wait_for_idle

      height = calculate_height(browser, open_fine_print_modal:)

      browser.resize(width:, height:)
      browser.screenshot(format: "png", encoding: :binary)
    ensure
      browser&.quit
    end

    def calculate_height(browser, open_fine_print_modal:)
      document_height = browser.evaluate(js_max_height_dimension)
      if open_fine_print_modal
        modal_height = browser.evaluate(%{ document.querySelector("dialog").scrollHeight })
        [modal_height, document_height].max
      else
        begin
          Timeout.timeout(ARTICLE_WAIT_TIMEOUT_SECONDS) do
            sleep 0.05 until browser.evaluate(%{ document.querySelector("article") !== null })
            sleep 0.1
          end
        rescue Timeout::Error
          return document_height
        end
        content_height = browser.evaluate(%{ document.querySelector("article")?.parentElement?.scrollHeight ?? 0 })
        [content_height, document_height].max
      end
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
