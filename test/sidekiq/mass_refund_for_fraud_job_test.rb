# frozen_string_literal: true

require "test_helper"

class MassRefundForFraudJobTest < ActiveSupport::TestCase
  setup do
    @admin_user = users(:admin_user)
    @product = links(:named_seller_product)
    @purchase1 = Struct.new(:external_id, :link_id).new("ext-1", @product.id)
    @purchase2 = Struct.new(:external_id, :link_id).new("ext-2", @product.id)
    @find_map = { "ext-1" => @purchase1, "ext-2" => @purchase2 }

    find_map = @find_map
    @find_mod = Module.new
    @find_mod.send(:define_method, :find_by_external_id) { |eid| find_map.key?(eid) ? find_map[eid] : nil }
    Purchase.singleton_class.prepend(@find_mod)

    @log_calls = []
    log_calls = @log_calls
    @log_mod = Module.new
    @log_mod.send(:define_method, :info) { |msg| log_calls << msg.to_s }
    Rails.logger.singleton_class.prepend(@log_mod)

    @notified = []
    notified = @notified
    @err_mod = Module.new
    @err_mod.send(:define_method, :notify) { |err, *_| notified << err }
    ErrorNotifier.singleton_class.prepend(@err_mod)
  end

  test "processes each purchase and logs results" do
    refunded_with = []
    @purchase1.define_singleton_method(:refund_for_fraud_and_block_buyer!) { |aid| refunded_with << [external_id, aid] }
    @purchase2.define_singleton_method(:refund_for_fraud_and_block_buyer!) { |aid| refunded_with << [external_id, aid] }

    MassRefundForFraudJob.new.perform(@product.id, ["ext-1", "ext-2"], @admin_user.id)

    assert_includes refunded_with, ["ext-1", @admin_user.id]
    assert_includes refunded_with, ["ext-2", @admin_user.id]
    assert @log_calls.any? { |m| m =~ /Mass fraud refund completed for product #{@product.id}: 2 succeeded, 0 failed/ }
  end

  test "handles missing purchases gracefully" do
    refunded_with = []
    @purchase1.define_singleton_method(:refund_for_fraud_and_block_buyer!) { |aid| refunded_with << aid }

    MassRefundForFraudJob.new.perform(@product.id, ["ext-1", "nonexistent"], @admin_user.id)

    assert_equal [@admin_user.id], refunded_with
    assert @log_calls.any? { |m| m =~ /Mass fraud refund completed for product #{@product.id}: 1 succeeded, 1 failed/ }
  end

  test "handles refund errors and continues processing" do
    @purchase1.define_singleton_method(:refund_for_fraud_and_block_buyer!) { |_aid| raise StandardError, "Refund failed" }
    p2_calls = []
    @purchase2.define_singleton_method(:refund_for_fraud_and_block_buyer!) { |aid| p2_calls << aid }

    MassRefundForFraudJob.new.perform(@product.id, ["ext-1", "ext-2"], @admin_user.id)

    assert_equal [@admin_user.id], p2_calls
    assert @notified.any? { |e| e.is_a?(StandardError) }
    assert @log_calls.any? { |m| m =~ /Mass fraud refund completed for product #{@product.id}: 1 succeeded, 1 failed/ }
  end
end
