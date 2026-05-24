# frozen_string_literal: true

require "test_helper"

class BalanceTest < ActiveSupport::TestCase
  setup do
    @user = users(:named_seller)
    @merchant_account = merchant_accounts(:forfeit_gumroad_stripe_account)
  end

  def create_balance
    Balance.create!(
      user: @user,
      merchant_account: @merchant_account,
      date: Date.today,
      amount_cents: 0,
      currency: "usd",
      holding_currency: "usd",
      holding_amount_cents: 0
    )
  end

  # ---- validate_amounts_are_only_changed_when_unpaid ----

  test "new balance creation succeeds without error" do
    assert_nothing_raised { create_balance }
  end

  test "updating balance's amounts is allowed when unpaid" do
    balance = create_balance
    balance.increment(:amount_cents, 1000)
    assert_nothing_raised { balance.save! }
  end

  test "raises an error if amount changed while processing" do
    balance = create_balance
    balance.mark_processing!
    balance.increment(:amount_cents, 1000)
    err = assert_raises(ActiveRecord::RecordInvalid) { balance.save! }
    assert_match(/Amount cents may not be changed in processing state/, err.message)
  end

  test "does not allow the balance's amounts to be updated when paid" do
    balance = create_balance
    balance.mark_processing!
    balance.mark_paid!
    balance.increment(:amount_cents, 1000)
    err = assert_raises(ActiveRecord::RecordInvalid) { balance.save! }
    assert_match(/Amount cents may not be changed in paid state/, err.message)
  end

  test "allows the balance's amounts to be updated when paid then marked unpaid again" do
    balance = create_balance
    balance.mark_processing!
    balance.mark_paid!
    balance.mark_unpaid!
    balance.increment(:amount_cents, 1000)
    assert_nothing_raised { balance.save! }
  end

  # ---- forfeited balances ----

  test "allows the balance to be forfeited" do
    balance = create_balance
    assert_nothing_raised { balance.mark_forfeited! }
  end

  # ---- #state ----

  test "has an initial state of unpaid" do
    assert_equal "unpaid", Balance.new.state
  end
end
