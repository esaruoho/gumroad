# frozen_string_literal: true

require "test_helper"

class SendPaymentReminderWorkerTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    Sidekiq::Worker.clear_all
    ActionMailer::Base.deliveries.clear
    # Other fixture users (paypal-seller, payout-annual-seller) also satisfy
    # the worker's scope; flip a flag column on them to drop them out of scope.
    User.where(email: ["paypal-seller@example.com", "payout-annual-seller@example.com"])
        .update_all(payment_address: "ignored-#{SecureRandom.hex(4)}@example.com")
    @user = users(:basic_user)
    # Match scopes: payment_reminder_risk_state, announcement_notification_enabled,
    # payment_address nil, balance > 1000.
    @user.update_columns(payment_address: nil, user_risk_state: "compliant", flags: 1)
    Balance.create!(user: @user, date: Date.current, amount_cents: 2000,
                    holding_amount_cents: 2000, state: "unpaid",
                    merchant_account_id: MerchantAccount.gumroad(StripeChargeProcessor.charge_processor_id).id)
  end

  test "notifies users to update payment information" do
    assert_enqueued_email_with(ContactingCreatorMailer, :remind, args: [@user.id], queue: "low") do
      SendPaymentReminderWorker.new.perform
    end
  end

  test "does not notify the user when they have an active stripe connect account" do
    ma = MerchantAccount.create!(user: @user, charge_processor_id: StripeChargeProcessor.charge_processor_id,
                                 charge_processor_merchant_id: "acct_test", charge_processor_alive_at: Time.current,
                                 currency: "usd", country: "US",
                                 json_data: { meta: { stripe_connect: "true" } })
    assert_no_enqueued_emails do
      SendPaymentReminderWorker.new.perform
    end

    ma.mark_deleted!
    assert_enqueued_email_with(ContactingCreatorMailer, :remind, args: [@user.id], queue: "low") do
      SendPaymentReminderWorker.new.perform
    end
  end

  test "does not notify the user when they have an active bank account" do
    BankAccount.create!(user: @user, type: "AchAccount",
                        routing_number: "110000000", account_number: "000123456789",
                        account_number_last_four: "6789", account_holder_full_name: "Test")
    assert_no_enqueued_emails do
      SendPaymentReminderWorker.new.perform
    end

    @user.active_bank_account.mark_deleted!
    assert_enqueued_email_with(ContactingCreatorMailer, :remind, args: [@user.id], queue: "low") do
      SendPaymentReminderWorker.new.perform
    end
  end
end
