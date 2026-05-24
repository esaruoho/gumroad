# frozen_string_literal: true

require "test_helper"

class PayoutUsersServiceTest < ActiveSupport::TestCase
  test "wraps user_ids into an array" do
    service = PayoutUsersService.new(
      date_string: "2024-01-01",
      processor_type: PayoutProcessorType::STRIPE,
      user_ids: 42
    )

    assert_equal [42], service.user_ids
  end

  test "accepts an explicit array of user_ids" do
    service = PayoutUsersService.new(
      date_string: "2024-01-01",
      processor_type: PayoutProcessorType::PAYPAL,
      user_ids: [1, 2, 3]
    )

    assert_equal [1, 2, 3], service.user_ids
  end

  test "defaults payout_type to standard" do
    service = PayoutUsersService.new(
      date_string: "2024-02-01",
      processor_type: PayoutProcessorType::STRIPE,
      user_ids: []
    )

    assert_equal Payouts::PAYOUT_TYPE_STANDARD, service.payout_type
  end

  test "honors explicit payout_type override" do
    service = PayoutUsersService.new(
      date_string: "2024-02-01",
      processor_type: PayoutProcessorType::STRIPE,
      user_ids: [1],
      payout_type: Payouts::PAYOUT_TYPE_INSTANT
    )

    assert_equal Payouts::PAYOUT_TYPE_INSTANT, service.payout_type
  end

  test "exposes date and processor_type readers" do
    service = PayoutUsersService.new(
      date_string: "2024-03-15",
      processor_type: PayoutProcessorType::PAYPAL,
      user_ids: [1]
    )

    assert_equal "2024-03-15", service.date
    assert_equal PayoutProcessorType::PAYPAL, service.processor_type
  end

  test "#process returns empty array when no user_ids supplied" do
    service = PayoutUsersService.new(
      date_string: "2024-04-01",
      processor_type: PayoutProcessorType::STRIPE,
      user_ids: []
    )

    assert_equal [], service.process
  end

  # TODO: end-to-end #create_payments + #process cross-border routing exercises
  # Payouts.create_payment, MerchantAccount + UserComplianceInfo
  # (encrypted/strongbox) + ProcessPaymentWorker.perform_in semantics. The
  # full original (spec/services/payout_users_service_spec.rb, 15 FB refs)
  # is deferred until those payout fixtures land.
end
