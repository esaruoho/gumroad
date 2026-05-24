# frozen_string_literal: true

require "test_helper"

class LowBalanceFraudCheckWorkerTest < ActiveSupport::TestCase
  test "invokes check_for_low_balance_and_probate for the seller" do
    purchase = purchases(:named_seller_call_purchase)
    called_with = nil
    mod = Module.new
    mod.send(:define_method, :check_for_low_balance_and_probate) { |pid| called_with = pid }
    User.prepend(mod)

    LowBalanceFraudCheckWorker.new.perform(purchase.id)

    assert_equal purchase.id, called_with
  ensure
    mod.module_eval { remove_method(:check_for_low_balance_and_probate) } if mod
  end
end
