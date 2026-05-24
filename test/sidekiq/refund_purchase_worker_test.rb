# frozen_string_literal: true

require "test_helper"

class RefundPurchaseWorkerTest < ActiveSupport::TestCase
  setup do
    @admin = users(:admin_user)
    @purchase = purchases(:email_sync_purchase_a)
  end

  test "calls refund_for_fraud_and_block_buyer! when reason is Refund::FRAUD" do
    called_with = nil
    @purchase.define_singleton_method(:refund_for_fraud_and_block_buyer!) do |admin_id|
      called_with = admin_id
    end
    @purchase.define_singleton_method(:refund_and_save!) do |_|
      raise "should not be called"
    end

    purchase = @purchase
    Purchase.stub(:find, ->(id) { id == purchase.id ? purchase : Purchase.find_by(id: id) }) do
      RefundPurchaseWorker.new.perform(@purchase.id, @admin.id, Refund::FRAUD)
    end

    assert_equal @admin.id, called_with
  end

  test "calls refund_and_save! when reason is not supplied" do
    called_with = nil
    @purchase.define_singleton_method(:refund_and_save!) do |admin_id|
      called_with = admin_id
    end
    @purchase.define_singleton_method(:refund_for_fraud_and_block_buyer!) do |_|
      raise "should not be called"
    end

    purchase = @purchase
    Purchase.stub(:find, ->(id) { id == purchase.id ? purchase : Purchase.find_by(id: id) }) do
      RefundPurchaseWorker.new.perform(@purchase.id, @admin.id)
    end

    assert_equal @admin.id, called_with
  end
end
