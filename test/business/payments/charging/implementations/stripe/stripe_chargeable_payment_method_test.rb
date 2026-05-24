# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during mig-b sweep.
# Relies on RSpec shared_examples — `it_behaves_like "a chargeable"` +
# `include_examples "stripe chargeable common"` (chargeable_protocol +
# stripe_chargeable_common_shared_examples) expand to dozens of additional
# expectations; shared-example machinery has no Minitest equivalent on
# this branch. Spec is also :vcr-tagged.
#
# Original spec: spec/business/payments/charging/implementations/stripe/stripe_chargeable_payment_method_spec.rb
class StripeChargeablePaymentMethodTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — shared_examples-bound, requires manual rewrite" do
    skip "TODO: migrate spec/business/payments/charging/implementations/stripe/stripe_chargeable_payment_method_spec.rb — shared_examples + VCR"
  end
end
