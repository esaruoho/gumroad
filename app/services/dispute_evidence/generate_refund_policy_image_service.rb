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
    # Should match $breakpoints definitions from app/javascript/stylesheets/_definitions.scss
    BREAKPOINT_SM = 640
    BREAKPOINT_LG = 1024

    IMAGE_RESIZE_FACTOR = 2
    IMAGE_QUALITY = 80

    attr_reader :url, :width, :open_fine_print_modal, :max_size_allowed

    def generate_screenshot
      kit = IMGKit.new(url, width: width, quality: 100, format: "png",
                            "javascript-delay": 2000,
                            "no-stop-slow-scripts": true,
                            "enable-javascript": true)
      kit.to_png
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
