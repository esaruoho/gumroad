# frozen_string_literal: true

require "test_helper"

class DisputeEvidence::GenerateReceiptImageServiceTest < ActiveSupport::TestCase
  FakeMailBody = Struct.new(:raw_source)
  FakeMail = Struct.new(:body, :from, :to, :subject, keyword_init: true)

  class FakeDriver
    attr_reader :quit_called

    def navigate = self
    def to(_url) = true
    def execute_script(_script) = 200
    def manage = self
    def window = self
    def size=(_dimension)
      true
    end
    def screenshot_as(format) = format == :png ? "png-binary" : nil
    def quit = @quit_called = true
  end

  class FakeImage
    attr_reader :width

    def initialize(width:, blob:)
      @width = width
      @blob = blob
    end

    def resize(_value) = self
    def format(_value) = self
    def quality(_value) = self
    def strip = self
    def to_blob = @blob
  end

  test ".perform generates a JPG receipt image" do
    purchase = purchases(:named_seller_call_purchase)
    driver = FakeDriver.new
    image = FakeImage.new(width: 1024, blob: "\xFF\xD8receipt\xFF\xD9".b)

    with_receipt_mailer(purchase) do
      Selenium::WebDriver.stub(:for, ->(browser, options:) {
        assert_equal :chrome, browser
        assert_instance_of Selenium::WebDriver::Chrome::Options, options
        driver
      }) do
        MiniMagick::Image.stub(:read, ->(binary_data) {
          assert_equal "png-binary", binary_data
          image
        }) do
          binary_data = DisputeEvidence::GenerateReceiptImageService.perform(purchase)

          assert binary_data.start_with?("\xFF\xD8".b)
          assert binary_data.end_with?("\xFF\xD9".b)
        end
      end
    end

    assert driver.quit_called
  end

  test "#generate_html generates the HTML for the receipt" do
    purchase = purchases(:named_seller_call_purchase)
    expected_html = <<~HTML
        <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
        <html><body>
                <div style="padding: 20px 20px">
                  <p><strong>Email receipt sent at:</strong> #{purchase.created_at}</p>
                  <p><strong>From:</strong> support@example.com</p>
                  <p><strong>To:</strong> customer@example.com</p>
                  <p><strong>Subject:</strong> You bought #{purchase.link.name}</p>
                </div>
                <hr>
              <p>receipt</p>
        </body></html>
    HTML

    with_receipt_mailer(purchase) do
      html = DisputeEvidence::GenerateReceiptImageService.new(purchase).send(:generate_html, purchase)

      assert_equal expected_html, html
    end
  end

  private
    def with_receipt_mailer(purchase)
      mail = FakeMail.new(
        body: FakeMailBody.new("<html><body><p>receipt</p></body></html>"),
        from: ["support@example.com"],
        to: ["customer@example.com"],
        subject: "You bought #{purchase.link.name}"
      )

      CustomerMailer.stub(:receipt, ->(purchase_id) {
        assert_equal purchase.id, purchase_id
        mail
      }) do
        yield
      end
    end
end
