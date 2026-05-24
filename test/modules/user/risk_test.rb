# frozen_string_literal: true

require "test_helper"

class UserRiskTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  include ActiveJob::TestHelper

  # Use users without product fixtures to avoid validation cascades on unpublish!
  def fresh_user
    users(:compliant_user_for_risk).tap { |u| u.update_columns(user_risk_state: "not_reviewed") }
  end

  def other_user
    users(:flagged_fraud_user_for_risk).tap { |u| u.update_columns(user_risk_state: "not_reviewed") }
  end

  test "#disable_refunds! disables refunds for the creator" do
    creator = fresh_user
    creator.disable_refunds!
    assert_equal true, creator.reload.refunds_disabled?
  end

  test "sends suspension email when suspended for TOS violation" do
    Feature.activate(:account_suspended_email)
    user = fresh_user
    user.flag_for_tos_violation!(author_name: "admin", bulk: true)
    assert_enqueued_email_with(ContactingCreatorMailer, :account_suspended, args: [user.id]) do
      user.suspend_for_tos_violation!(author_name: "admin")
    end
  end

  test "sends suspension email when suspended for fraud" do
    Feature.activate(:account_suspended_email)
    user = fresh_user
    user.flag_for_fraud!(author_name: "admin")
    assert_enqueued_email_with(ContactingCreatorMailer, :account_suspended, args: [user.id]) do
      user.suspend_for_fraud!(author_name: "admin")
    end
  end

  test "skips generic suspension email when skip_generic_suspension_email is passed" do
    Feature.activate(:account_suspended_email)
    user = fresh_user
    user.flag_for_tos_violation!(author_name: "admin", bulk: true)
    assert_no_enqueued_emails do
      user.suspend_for_tos_violation!(author_name: "admin", skip_generic_suspension_email: true)
    end
  end

  test "does not send generic suspension email when feature flag inactive" do
    Feature.deactivate(:account_suspended_email)
    user = fresh_user
    user.flag_for_tos_violation!(author_name: "admin", bulk: true)
    assert_no_enqueued_emails do
      user.suspend_for_tos_violation!(author_name: "admin")
    end
  end

  test "#suspend_due_to_stripe_risk sends stripe-risk email and not generic one" do
    Feature.activate(:account_suspended_email)
    user = fresh_user
    assert_enqueued_email_with(ContactingCreatorMailer, :suspended_due_to_stripe_risk, args: [user.id]) do
      user.suspend_due_to_stripe_risk
    end

    another_user = other_user
    another_user.suspend_due_to_stripe_risk
    suspended_jobs = enqueued_jobs.select { |j| j["job_class"] == "ActionMailer::MailDeliveryJob" && j["arguments"][1] == "account_suspended" }
    suspended_jobs += ActiveJob::Base.queue_adapter.enqueued_jobs.select { |j| j[:job] == ActionMailer::MailDeliveryJob && j[:args][1] == "account_suspended" }
    assert_empty suspended_jobs
  end

  test "#suspend_sellers_other_accounts enqueues SuspendAccountsWithPaymentAddressWorker once for PayPal accounts" do
    user = fresh_user
    user.update!(payment_address: "test@example.com")
    other = other_user
    other.update!(payment_address: "test@example.com")

    transition = Minitest::Mock.new
    transition.expect(:args, [])

    assert_difference -> { SuspendAccountsWithPaymentAddressWorker.jobs.size }, 1 do
      user.suspend_sellers_other_accounts(transition)
    end
    assert_equal [user.id], SuspendAccountsWithPaymentAddressWorker.jobs.last["args"]

    assert_difference -> { SuspendAccountsWithPaymentAddressWorker.jobs.size }, -1 do
      SuspendAccountsWithPaymentAddressWorker.perform_one
    end
  end

  test "#unblock_seller_ip! does nothing when last_sign_in_ip blank" do
    user = fresh_user
    user.update_column(:last_sign_in_ip, nil)
    assert_nothing_raised { user.unblock_seller_ip! }
  end

  test "#unblock_seller_ip! only unblocks rows scoped to ip_address type" do
    ip = "203.0.113.42"
    user = fresh_user
    user.update_column(:last_sign_in_ip, ip)

    email_block = PlatformBlock.add!(object_type: PlatformBlock::TYPES[:email], object_value: ip)
    ip_block = PlatformBlock.add!(object_type: PlatformBlock::TYPES[:ip_address], object_value: ip, expires_in: 1.hour)

    user.unblock_seller_ip!

    assert_nil ip_block.reload.blocked_at
    assert_not_nil email_block.reload.blocked_at
  end
end
