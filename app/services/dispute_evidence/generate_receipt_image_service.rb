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
      ErrorNotifier.notify("DisputeEvidence::GenerateReceiptImageService: Could not generate screenshot for purchase ID #{purchase.id}")
      return
    end

    optimize_image(binary_data)
  end

  private
    BREAKPOINT_LG = 1024

    IMAGE_RESIZE_FACTOR = 2
    IMAGE_QUALITY = 80

    attr_reader :purchase
    attr_accessor :width

    def generate_screenshot
      @width = BREAKPOINT_LG
      html = generate_html(purchase)

      kit = IMGKit.new(html, width: width, quality: 100, format: "png")
      kit.to_png
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
