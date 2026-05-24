# frozen_string_literal: true

require "test_helper"

class CheckPaymentAddressWorkerTest < ActiveSupport::TestCase
  setup do
    @suspended_with_payment_address = users(:suspended_fraud_user_with_payment_address)
    PlatformBlock.add!(object_type: PlatformBlock::TYPES[:email], object_value: "fraudulent_email@zombo.com")
  end

  test "does not flag the user for fraud if there are no other banned users with the same payment address" do
    user = users(:check_payment_address_clean_user)

    CheckPaymentAddressWorker.new.perform(user.id)

    assert_equal false, user.reload.flagged_for_fraud?
  end

  test "flags the user for fraud if there are other banned users with the same payment address" do
    user = users(:check_payment_address_colliding_user)

    CheckPaymentAddressWorker.new.perform(user.id)

    assert_equal true, user.reload.flagged_for_fraud?
  end

  test "flags the user for fraud if a blocked email PlatformBlock exists for their payment address" do
    user = users(:check_payment_address_blocked_user)

    CheckPaymentAddressWorker.new.perform(user.id)

    assert_equal true, user.reload.flagged_for_fraud?
  end
end
