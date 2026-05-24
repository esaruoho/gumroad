# frozen_string_literal: true

require "test_helper"

class SubscribePreviewGeneratorServiceTest < ActiveSupport::TestCase
  test "constants are configured for retina viewport" do
    assert_equal 2, SubscribePreviewGeneratorService::RETINA_PIXEL_RATIO
    assert_equal 512, SubscribePreviewGeneratorService::WIDTH
    assert_equal 128 / 67r, SubscribePreviewGeneratorService::ASPECT_RATIO
    assert_equal 512 / (128 / 67r), SubscribePreviewGeneratorService::HEIGHT
  end

  test "Chrome args include headless and sandbox flags" do
    args = SubscribePreviewGeneratorService::CHROME_ARGS
    assert_includes args, "headless"
    assert_includes args, "no-sandbox"
    assert_includes args, "disable-setuid-sandbox"
    assert_includes args, "disable-dev-shm-usage"
    assert(args.any? { |a| a.start_with?("force-device-scale-factor=") })
  end

  # The integration path (generate_pngs) boots a real Selenium-driven Chromium
  # to render the page, which is the system-spec lane (Capybara/Selenium).
  # That harness is not wired into the Minitest pass. Original:
  # spec/services/subscribe_preview_generator_service_spec.rb
end
