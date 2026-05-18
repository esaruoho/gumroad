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
      "headless" => "new",
      "no-sandbox" => nil,
      "disable-setuid-sandbox" => nil,
      "disable-dev-shm-usage" => nil,
      "user-data-dir" => "/tmp/chrome",
      "disable-scrollbars" => nil,
    }.freeze

    BREAKPOINT_SM = 640
    BREAKPOINT_LG = 1024

    IMAGE_RESIZE_FACTOR = 2
    IMAGE_QUALITY = 80
    ARTICLE_WAIT_TIMEOUT_SECONDS = 5

    attr_reader :url, :width, :open_fine_print_modal, :max_size_allowed

    def generate_screenshot
      browser = Ferrum::Browser.new(
        browser_options: BROWSER_OPTIONS,
        headless: false,
        window_size: [width, width],
        process_timeout: 30,
        timeout: 10,
      )
      browser.goto(url)
      browser.resize(width: width, height: calculate_height(browser))
      browser.screenshot(format: "png", encoding: :binary)
    ensure
      browser&.quit
    end

    def calculate_height(browser)
      document_height = (browser.evaluate(js_max_height_dimension) || 0).to_i
      if open_fine_print_modal
        wait_for_selector(browser, "dialog")
        modal_height = (browser.evaluate(%{(() => { const dialog = document.querySelector("dialog"); return dialog ? dialog.scrollHeight : 0; })()}) || 0).to_i
        [modal_height, document_height].max
      else
        wait_for_selector(browser, "article")
        content_height = (browser.evaluate(%{(() => { const article = document.querySelector("article"); return article?.parentElement ? article.parentElement.scrollHeight : 0; })()}) || 0).to_i
        [content_height, document_height].max
      end
    end

    def wait_for_selector(browser, selector)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + ARTICLE_WAIT_TIMEOUT_SECONDS
      loop do
        return if browser.evaluate(%{document.querySelector(#{selector.to_json}) !== null})
        return if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
        sleep 0.05
      end
    end

    def js_max_height_dimension
      %{
        Math.max(
          document.body.scrollHeight,
          document.body.offsetHeight,
          document.documentElement.clientHeight,
          document.documentElement.scrollHeight,
          document.documentElement.offsetHeight,
        );
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
