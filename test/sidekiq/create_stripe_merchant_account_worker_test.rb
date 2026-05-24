# frozen_string_literal: true

require "test_helper"

class CreateStripeMerchantAccountWorkerTest < ActiveSupport::TestCase
  test "creates an account for the user" do
    user = users(:named_seller)
    received_user = nil
    received_passphrase = nil

    StripeMerchantAccountManager.stub(:create_account, ->(u, passphrase:) { received_user = u; received_passphrase = passphrase }) do
      CreateStripeMerchantAccountWorker.new.perform(user.id)
    end

    assert_equal user, received_user
    assert_equal GlobalConfig.get("STRONGBOX_GENERAL_PASSWORD"), received_passphrase
  end

  test "propagates Stripe::InvalidRequestError" do
    user = users(:named_seller)
    error_message = "Invalid account number: must contain only digits, and be at most 12 digits long"

    StripeMerchantAccountManager.stub(:create_account, ->(*, **) { raise Stripe::InvalidRequestError.new(error_message, nil) }) do
      assert_raises(Stripe::InvalidRequestError) do
        CreateStripeMerchantAccountWorker.new.perform(user.id)
      end
    end
  end
end
