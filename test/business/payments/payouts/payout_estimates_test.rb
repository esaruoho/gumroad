# frozen_string_literal: true

require "test_helper"

class PayoutEstimatesTest < ActiveSupport::TestCase
  # Anchor the payout date the same way the fixtures do.
  PAYOUT_DATE = Date.today - 1
  PAYOUT_PROCESSOR_TYPE = PayoutProcessorType::STRIPE

  setup do
    @u0 = users(:payout_estimates_user_0)
    @u1 = users(:payout_estimates_user_1)
    @u2 = users(:payout_estimates_user_2)
    @u3 = users(:payout_estimates_user_3)
  end

  # ---- estimate_held_amount_cents ----------------------------------------

  test "estimate_held_amount_cents returns aggregate of amount held at each holder of funds" do
    held = PayoutEstimates.estimate_held_amount_cents(PAYOUT_DATE, PAYOUT_PROCESSOR_TYPE)
    assert_equal 260_00, held[HolderOfFunds::STRIPE]
    assert_equal 20_00, held[HolderOfFunds::GUMROAD]
  end

  # ---- estimate_payments_for_balances_up_to_date_for_users ---------------

  test "estimate_payments_for_balances_up_to_date_for_users does not mark balances being paid as processing" do
    PayoutEstimates.estimate_payments_for_balances_up_to_date_for_users(
      PAYOUT_DATE, PAYOUT_PROCESSOR_TYPE, [@u0, @u2, @u3]
    )
    assert_equal "unpaid", balances(:poe_user_0_bal_gumroad).reload.state
    assert_equal "unpaid", balances(:poe_user_0_bal_stripe_in).reload.state
    assert_equal "unpaid", balances(:poe_user_2_bal_a).reload.state
    assert_equal "unpaid", balances(:poe_user_2_bal_b).reload.state
  end

  test "estimate_payments_for_balances_up_to_date_for_users does not mark out-of-window balances as processing" do
    PayoutEstimates.estimate_payments_for_balances_up_to_date_for_users(
      PAYOUT_DATE, PAYOUT_PROCESSOR_TYPE, [@u0, @u3]
    )
    assert_equal "unpaid", balances(:poe_user_0_bal_stripe_out).reload.state
    assert_equal "unpaid", balances(:poe_user_3_bal).reload.state
  end

  test "estimate_payments_for_balances_up_to_date_for_users does not deduct the balance from the user" do
    PayoutEstimates.estimate_payments_for_balances_up_to_date_for_users(
      PAYOUT_DATE, PAYOUT_PROCESSOR_TYPE, [@u0, @u2, @u3]
    )
    assert_equal 111_000, @u0.unpaid_balance_cents
    assert_equal 60_00, @u2.unpaid_balance_cents
    assert_equal 10_00, @u3.unpaid_balance_cents
  end

  test "estimate_payments_for_balances_up_to_date_for_users does not create payments for payable users" do
    before_counts = [@u0.payments.count, @u2.payments.count, @u3.payments.count]
    PayoutEstimates.estimate_payments_for_balances_up_to_date_for_users(
      PAYOUT_DATE, PAYOUT_PROCESSOR_TYPE, [@u0, @u2, @u3]
    )
    after_counts = [@u0.payments.reload.count, @u2.payments.reload.count, @u3.payments.reload.count]
    assert_equal before_counts, after_counts
  end

  test "estimate_payments_for_balances_up_to_date_for_users returns estimates with holder-of-funds breakdown" do
    estimates = PayoutEstimates.estimate_payments_for_balances_up_to_date_for_users(
      PAYOUT_DATE, PAYOUT_PROCESSOR_TYPE, [@u0, @u2, @u3]
    )

    # u3 is not payable: their balance (10_00) is below the minimum payout amount
    # and they have no payment top-up. They should be excluded from estimates.
    estimate_user_ids = estimates.map { |e| e[:user].id }
    refute_includes estimate_user_ids, @u3.id

    u0_estimate = estimates.find { |e| e[:user].id == @u0.id }
    refute_nil u0_estimate
    assert_equal 110_00, u0_estimate[:amount_cents]
    assert_equal({ HolderOfFunds::GUMROAD => 10_00, HolderOfFunds::STRIPE => 100_00 }, u0_estimate[:holder_of_funds_amount_cents])

    u2_estimate = estimates.find { |e| e[:user].id == @u2.id }
    refute_nil u2_estimate
    assert_equal 60_00, u2_estimate[:amount_cents]
    assert_equal({ HolderOfFunds::STRIPE => 60_00 }, u2_estimate[:holder_of_funds_amount_cents])
  end
end
