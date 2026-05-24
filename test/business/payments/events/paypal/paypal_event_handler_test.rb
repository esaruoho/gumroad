# frozen_string_literal: true

require "test_helper"

class PaypalEventHandlerTest < ActiveSupport::TestCase
  test "skipped: VCR-required" do
    skip "PaypalEventHandler spec mixes :vcr tagged describe blocks (purchase/express_checkout IPN paths hitting PayPal sandbox), WebMock IPN verification stubs, expect_any_instance_of(PaypalMerchantAccountManager), and FactoryBot create(:payment). Migration requires VCR cassettes + payment fixtures; VCR is not yet wired into Minitest. Covered by RSpec."
  end
end
