# frozen_string_literal: true

require "test_helper"

class ForfeitBalanceServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:forfeit_user)
    @merchant_account = merchant_accounts(:forfeit_user_stripe_account)
  end

  # ---------- country_change ----------
  class CountryChange < ActiveSupport::TestCase
    setup do
      @user = users(:forfeit_user)
      @merchant_account = merchant_accounts(:forfeit_user_stripe_account)
      @service = ForfeitBalanceService.new(user: @user, reason: :country_change)
    end

    # #process — no unpaid balance
    test "process returns nil when the user doesn't have an unpaid balance" do
      assert_nil @service.process
      assert_nil @user.reload.comments.last
    end

    # #process — with unpaid balance
    test "process marks the balances as forfeited" do
      balance = Balance.create!(merchant_account: @merchant_account, user: @user, amount_cents: 1050, date: Date.current)
      @service.process
      assert_equal "forfeited", balance.reload.state
      assert_equal 0, @user.reload.unpaid_balance_cents
    end

    test "process adds a comment on the user" do
      Balance.create!(merchant_account: @merchant_account, user: @user, amount_cents: 1050, date: Date.current)
      @service.process
      comment = @user.reload.comments.last
      assert_equal Comment::COMMENT_TYPE_BALANCE_FORFEITED, comment.comment_type
      assert_equal "Balance of $10.50 has been forfeited. Reason: Country changed. Balance IDs: #{Balance.last.id}", comment.content
    end

    test "process does not add a negative credit" do
      Balance.create!(merchant_account: @merchant_account, user: @user, amount_cents: 1050, date: Date.current)
      @service.process
      assert_nil @user.reload.credits.last
    end

    # #balance_amount_cents_to_forfeit
    test "balance_amount_cents_to_forfeit returns the correctly formatted balance" do
      Balance.create!(user: @user, merchant_account: @merchant_account, amount_cents: 765, date: Date.current)
      assert_equal 765, @service.balance_amount_cents_to_forfeit
    end

    test "balance_amount_cents_to_forfeit excludes balances held by Gumroad" do
      gumroad_ma = MerchantAccount.gumroad(StripeChargeProcessor.charge_processor_id)
      assert gumroad_ma, "expected gumroad stripe merchant account fixture"
      Balance.create!(user: @user, merchant_account: gumroad_ma, amount_cents: 765, date: Date.current)
      assert_equal 0, @service.balance_amount_cents_to_forfeit
    end

    # #balance_amount_formatted
    test "balance_amount_formatted returns the correctly formatted balance" do
      Balance.create!(user: @user, merchant_account: @merchant_account, amount_cents: 680, date: Date.current)
      assert_equal "$6.80", @service.balance_amount_formatted
    end
  end

  # ---------- account_closure ----------
  class AccountClosure < ActiveSupport::TestCase
    setup do
      @user = users(:forfeit_user)
      @merchant_account = merchant_accounts(:forfeit_user_stripe_account)
      @gumroad_stripe = MerchantAccount.gumroad(StripeChargeProcessor.charge_processor_id)
      @service = ForfeitBalanceService.new(user: @user, reason: :account_closure)
    end

    test "process returns nil when the user doesn't have an unpaid balance" do
      assert_nil @service.process
      assert_nil @user.reload.comments.last
    end

    test "process marks balances as forfeited when user has a positive unpaid balance" do
      balance = Balance.create!(user: @user, merchant_account: @gumroad_stripe, amount_cents: 876, date: Date.current)
      @service.process
      assert_equal "forfeited", balance.reload.state
      assert_equal 0, @user.reload.unpaid_balance_cents
    end

    test "process adds a comment on the user when balance is positive" do
      Balance.create!(user: @user, merchant_account: @gumroad_stripe, amount_cents: 876, date: Date.current)
      @service.process
      comment = @user.reload.comments.last
      assert_equal Comment::COMMENT_TYPE_BALANCE_FORFEITED, comment.comment_type
      assert_equal "Balance of $8.76 has been forfeited. Reason: Account closed. Balance IDs: #{Balance.last.id}", comment.content
    end

    test "process does not add a negative credit when balance is positive" do
      Balance.create!(user: @user, merchant_account: @gumroad_stripe, amount_cents: 876, date: Date.current)
      @service.process
      assert_nil @user.reload.credits.last
    end

    test "process doesn't forfeit a negative unpaid balance" do
      balance = Balance.create!(user: @user, merchant_account: @merchant_account, amount_cents: -765, date: Date.current)
      assert_nil @service.process
      assert_equal "unpaid", balance.reload.state
      assert_nil @user.reload.comments.last
    end

    test "balance_amount_cents_to_forfeit returns the correct amount" do
      Balance.create!(user: @user, merchant_account: @gumroad_stripe, amount_cents: 850, date: Date.current)
      assert_equal 850, @service.balance_amount_cents_to_forfeit
    end

    test "balance_amount_formatted returns the correctly formatted balance" do
      Balance.create!(user: @user, merchant_account: @gumroad_stripe, amount_cents: 589, date: Date.current)
      assert_equal "$5.89", @service.balance_amount_formatted
    end
  end
end
