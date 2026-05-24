# frozen_string_literal: true

require "test_helper"

class User::PayoutInfoTest < ActiveSupport::TestCase
  setup do
    @user = users(:payout_info_user)
    @bank_account = bank_accounts(:payout_info_uk_bank_account)
    @manual_payout_end_date = Date.today
  end

  def add_paused_comment(content)
    Comment.create!(commentable: @user, comment_type: Comment::COMMENT_TYPE_PAYOUTS_PAUSED, content: content, author_name: "Admin")
  end

  def with_end_date(&block)
    User::PayoutSchedule.stub(:manual_payout_end_date, @manual_payout_end_date, &block)
  end

  test "includes payout information" do
    add_paused_comment("Paused due to review")
    with_end_date do
      Payouts.stub(:is_user_payable, false) do
        result = @user.payout_info
        assert_equal(
          { "type" => @bank_account.type, "account_holder_full_name" => @bank_account.account_holder_full_name, "formatted_account" => @bank_account.formatted_account },
          result[:active_bank_account]
        )
        assert_equal "test@example.com", result[:payment_address]
        assert_equal User::PAYOUT_PAUSE_SOURCE_ADMIN, result[:payouts_paused_by_source]
        assert_equal "Paused due to review", result[:payouts_paused_for_reason]
      end
    end
  end

  test "returns nil for active_bank_account when none exists" do
    @bank_account.destroy!
    with_end_date do
      Payouts.stub(:is_user_payable, false) do
        result = @user.payout_info
        assert_nil result[:active_bank_account]
      end
    end
  end

  test "returns nil for payouts_paused_for_reason when no paused comment" do
    with_end_date do
      Payouts.stub(:is_user_payable, false) do
        result = @user.payout_info
        assert_nil result[:payouts_paused_for_reason]
      end
    end
  end

  test "stripe payable from admin: includes manual payout info with stripe info" do
    stripe_account = merchant_accounts(:payout_info_stripe_account)

    payable_responder = lambda do |_user, _date, processor_type:, from_admin: false|
      processor_type == PayoutProcessorType::STRIPE
    end

    @user.define_singleton_method(:unpaid_balance_cents_up_to_date) { |_d| 10_000 }
    @user.define_singleton_method(:unpaid_balance_cents_up_to_date_held_by_gumroad) { |_d| 5_000 }
    @user.define_singleton_method(:unpaid_balance_holding_cents_up_to_date_held_by_stripe) { |_d| 5_000 }

    with_end_date do
      Payouts.stub(:is_user_payable, payable_responder) do
        result = @user.payout_info
        assert_equal(
          {
            stripe: { unpaid_balance_held_by_gumroad: "$50", unpaid_balance_held_by_stripe: "50 USD" },
            paypal: nil,
            unpaid_balance_up_to_date: 10_000,
            currency: stripe_account.currency,
            manual_payout_period_end_date: @manual_payout_end_date,
            ask_confirmation: false,
          },
          result[:manual_payout_info]
        )
      end
    end
  end

  test "paypal payable from admin: includes manual payout info with paypal info" do
    stripe_account = merchant_accounts(:payout_info_stripe_account)

    payable_responder = lambda do |_user, _date, processor_type:, from_admin: false|
      processor_type == PayoutProcessorType::PAYPAL
    end

    @user.define_singleton_method(:unpaid_balance_cents_up_to_date) { |_d| 10_000 }
    @user.define_singleton_method(:should_paypal_payout_be_split?) { true }

    with_end_date do
      PaypalPayoutProcessor.stub(:split_payment_by_cents, ->(_u) { 5_000 }) do
        Payouts.stub(:is_user_payable, payable_responder) do
          result = @user.payout_info
          assert_equal(
            {
              stripe: nil,
              paypal: { should_payout_be_split: true, split_payment_by_cents: 5_000 },
              unpaid_balance_up_to_date: 10_000,
              currency: stripe_account.currency,
              manual_payout_period_end_date: @manual_payout_end_date,
              ask_confirmation: false,
            },
            result[:manual_payout_info]
          )
        end
      end
    end
  end

  test "not payable via stripe or paypal from admin: no manual_payout_info" do
    merchant_accounts(:payout_info_stripe_account)
    with_end_date do
      Payouts.stub(:is_user_payable, false) do
        result = @user.payout_info
        assert_nil result[:manual_payout_info]
      end
    end
  end

  test "last payout exists: no manual_payout_info" do
    Payment.create!(user: @user, state: "processing", processor: "paypal", correlation_id: "payout-info-last", amount_cents: 100, payout_period_end_date: Date.yesterday)
    with_end_date do
      Payouts.stub(:is_user_payable, true) do
        result = @user.payout_info
        assert_nil result[:manual_payout_info]
      end
    end
  end
end
