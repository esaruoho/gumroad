require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration —
# 26 FB refs across 885 lines, heavily coupled to Purchase + Charge + Stripe
# payment flow + subscription billing. Documented skip-batch territory.
#
# Original spec: spec/presenters/receipt_presenter/payment_info_spec.rb (26 FB refs)
class ReceiptPresenter::PaymentInfoTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — payment/charge deep-web, requires manual rewrite" do
    skip "TODO: migrate spec/presenters/receipt_presenter/payment_info_spec.rb (26 FB refs, 885 lines)"
  end
end
