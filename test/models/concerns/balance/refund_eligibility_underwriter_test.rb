# frozen_string_literal: true

require "test_helper"

class Balance::RefundEligibilityUnderwriterTest < ActiveSupport::TestCase
  setup do
    @balance = balances(:refund_eligibility_balance)
    @user = @balance.user
    UpdateSellerRefundEligibilityJob.jobs.clear
  end

  test "does not enqueue the job when user_id is blank" do
    @balance.user_id = nil
    @balance.update!(holding_amount_cents: 5000)
    assert_equal 0, UpdateSellerRefundEligibilityJob.jobs.size
  end

  test "enqueues the job when balance increases and refunds are disabled" do
    @user.disable_refunds!
    UpdateSellerRefundEligibilityJob.jobs.clear
    @balance.update!(amount_cents: 2000)
    assert_equal 1, UpdateSellerRefundEligibilityJob.jobs.size
    assert_equal [@user.id], UpdateSellerRefundEligibilityJob.jobs.first["args"]
  end

  test "does not enqueue the job when balance increases and refunds are enabled" do
    @user.enable_refunds!
    UpdateSellerRefundEligibilityJob.jobs.clear
    @balance.update!(amount_cents: 2000)
    assert_equal 0, UpdateSellerRefundEligibilityJob.jobs.size
  end

  test "does not enqueue the job when balance decreases and refunds are disabled" do
    @user.disable_refunds!
    UpdateSellerRefundEligibilityJob.jobs.clear
    @balance.update!(amount_cents: 500)
    assert_equal 0, UpdateSellerRefundEligibilityJob.jobs.size
  end

  test "enqueues the job when balance decreases and refunds are enabled" do
    @user.enable_refunds!
    UpdateSellerRefundEligibilityJob.jobs.clear
    @balance.update!(amount_cents: 500)
    assert_equal 1, UpdateSellerRefundEligibilityJob.jobs.size
    assert_equal [@user.id], UpdateSellerRefundEligibilityJob.jobs.first["args"]
  end

  test "does not enqueue the job when amount_cents does not change" do
    @balance.mark_processing!
    assert_equal 0, UpdateSellerRefundEligibilityJob.jobs.size
  end
end
