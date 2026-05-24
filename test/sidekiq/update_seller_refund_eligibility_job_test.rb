# frozen_string_literal: true

require "test_helper"

class UpdateSellerRefundEligibilityJobTest < ActiveSupport::TestCase
  setup do
    @user = users(:named_seller)
  end

  test "enables refunds when unpaid balance positive and refunds were disabled" do
    @user.define_singleton_method(:unpaid_balance_cents) { 5_000 }
    @user.define_singleton_method(:refunds_disabled?) { true }
    enable_called = false
    disable_called = false
    check_called = false
    @user.define_singleton_method(:enable_refunds!) { enable_called = true }
    @user.define_singleton_method(:disable_refunds!) { disable_called = true }
    @user.define_singleton_method(:check_for_high_balance_and_remove_low_balance_probation!) { check_called = true }
    User.stub(:find, ->(_id) { @user }) do
      UpdateSellerRefundEligibilityJob.new.perform(@user.id)
    end
    assert enable_called
    refute disable_called
    assert check_called
  end

  test "disables refunds when unpaid balance below -100 dollars and refunds not disabled" do
    @user.define_singleton_method(:unpaid_balance_cents) { -20_000 }
    @user.define_singleton_method(:refunds_disabled?) { false }
    enable_called = false
    disable_called = false
    @user.define_singleton_method(:enable_refunds!) { enable_called = true }
    @user.define_singleton_method(:disable_refunds!) { disable_called = true }
    @user.define_singleton_method(:check_for_high_balance_and_remove_low_balance_probation!) {}
    User.stub(:find, ->(_id) { @user }) do
      UpdateSellerRefundEligibilityJob.new.perform(@user.id)
    end
    refute enable_called
    assert disable_called
  end

  test "no-op when balance is within range" do
    @user.define_singleton_method(:unpaid_balance_cents) { 0 }
    @user.define_singleton_method(:refunds_disabled?) { false }
    enable_called = false
    disable_called = false
    check_called = false
    @user.define_singleton_method(:enable_refunds!) { enable_called = true }
    @user.define_singleton_method(:disable_refunds!) { disable_called = true }
    @user.define_singleton_method(:check_for_high_balance_and_remove_low_balance_probation!) { check_called = true }
    User.stub(:find, ->(_id) { @user }) do
      UpdateSellerRefundEligibilityJob.new.perform(@user.id)
    end
    refute enable_called
    refute disable_called
    assert check_called
  end
end
