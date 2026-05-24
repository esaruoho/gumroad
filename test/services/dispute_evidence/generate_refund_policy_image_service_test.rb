# frozen_string_literal: true

require "test_helper"

class DisputeEvidence::GenerateRefundPolicyImageServiceTest < ActiveSupport::TestCase
  class FakeDriver
    attr_reader :scripts, :quit_called, :window_sizes

    def initialize(screenshot: "png-binary", document_height: 1_000, article_height: 1_500)
      @screenshot = screenshot
      @document_height = document_height
      @article_height = article_height
      @scripts = []
      @window_sizes = []
    end

    def navigate = self
    def manage = self
    def window = self

    def to(_url)
      true
    end

    def size=(dimension)
      @window_sizes << dimension
    end

    def execute_script(script)
      @scripts << script
      case script
      when /readyState/ then "complete"
      when /Math\.max/ then @document_height
      when /querySelector\("article"\) !== null/ then true
      when /parentElement\?\.scrollHeight/ then @article_height
      else nil
      end
    end

    def screenshot_as(format)
      format == :png ? @screenshot : nil
    end

    def quit
      @quit_called = true
    end
  end

  FakeImage = Struct.new(:width, :size, :blob) do
    def resize(_value) = self
    def format(_value) = self
    def quality(_value) = self
    def strip = self
    def to_blob = blob
  end

  class FakeWait
    def initialize(result: true, error: nil)
      @result = result
      @error = error
    end

    def until
      raise @error if @error

      yield if block_given?
      @result
    end
  end

  setup do
    @service = DisputeEvidence::GenerateRefundPolicyImageService.new(
      "https://example.com",
      mobile_purchase: false,
      open_fine_print_modal: false,
      max_size_allowed: 5_000_000
    )
  end

  test "#calculate_height returns the larger of the article and document heights" do
    driver = FakeDriver.new
    wait = FakeWait.new

    Selenium::WebDriver::Wait.stub(:new, wait) do
      assert_equal 1_500, @service.send(:calculate_height, driver, open_fine_print_modal: false)
    end
  end

  test "#calculate_height falls back to the document height when the article never mounts" do
    driver = FakeDriver.new
    wait = FakeWait.new(error: Selenium::WebDriver::Error::TimeoutError)

    Selenium::WebDriver::Wait.stub(:new, wait) do
      assert_equal 1_000, @service.send(:calculate_height, driver, open_fine_print_modal: false)
    end
    assert_not driver.scripts.any? { _1.match?(/parentElement/) }
  end

  test ".perform generates a JPG image" do
    driver = FakeDriver.new
    image = FakeImage.new(1024, 2_000, "\xFF\xD8refund-policy\xFF\xD9".b)

    with_browser_and_image(driver:, image:) do
      binary_data = DisputeEvidence::GenerateRefundPolicyImageService.perform(
        url: "https://example.com",
        mobile_purchase: false,
        open_fine_print_modal: false,
        max_size_allowed: 3_000_000.bytes
      )

      assert binary_data.start_with?("\xFF\xD8".b)
      assert binary_data.end_with?("\xFF\xD9".b)
    end

    assert driver.quit_called
  end

  test ".perform raises when the image is too large" do
    driver = FakeDriver.new
    image = FakeImage.new(1024, 2_000, "\xFF\xD8refund-policy\xFF\xD9".b)

    with_browser_and_image(driver:, image:) do
      assert_raises(DisputeEvidence::GenerateRefundPolicyImageService::ImageTooLargeError) do
        DisputeEvidence::GenerateRefundPolicyImageService.perform(
          url: "https://example.com",
          mobile_purchase: false,
          open_fine_print_modal: false,
          max_size_allowed: 1_000.bytes
        )
      end
    end

    assert driver.quit_called
  end

  private
    def with_browser_and_image(driver:, image:)
      Selenium::WebDriver.stub(:for, ->(browser, options:) {
        assert_equal :chrome, browser
        assert_instance_of Selenium::WebDriver::Chrome::Options, options
        driver
      }) do
        Selenium::WebDriver::Wait.stub(:new, FakeWait.new) do
          MiniMagick::Image.stub(:read, ->(binary_data) {
            assert_equal "png-binary", binary_data
            image
          }) do
            yield
          end
        end
      end
    end
end
