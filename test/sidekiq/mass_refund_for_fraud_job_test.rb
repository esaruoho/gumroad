# frozen_string_literal: true

require "test_helper"

class MassRefundForFraudJobTest < ActiveSupport::TestCase
  setup do
    @admin_user = users(:admin_user)
    @product = links(:named_seller_product)
  end

  test "processes each purchase and logs results" do
    purchase1 = Minitest::Mock.new
    purchase1.expect(:link_id, @product.id)
    purchase1.expect(:refund_for_fraud_and_block_buyer!, nil, [@admin_user.id])

    purchase2 = Minitest::Mock.new
    purchase2.expect(:link_id, @product.id)
    purchase2.expect(:refund_for_fraud_and_block_buyer!, nil, [@admin_user.id])

    finder = ->(ext_id) { { "ext-1" => purchase1, "ext-2" => purchase2 }[ext_id] }

    logger_messages = []
    Purchase.stub(:find_by_external_id, finder) do
      Rails.logger.stub(:info, ->(msg) { logger_messages << msg }) do
        MassRefundForFraudJob.new.perform(@product.id, ["ext-1", "ext-2"], @admin_user.id)
      end
    end

    assert purchase1.verify
    assert purchase2.verify
    assert logger_messages.any? { |m| m =~ /Mass fraud refund completed for product #{@product.id}: 2 succeeded, 0 failed/ }
  end

  test "handles missing purchases gracefully" do
    purchase1 = Minitest::Mock.new
    purchase1.expect(:link_id, @product.id)
    purchase1.expect(:refund_for_fraud_and_block_buyer!, nil, [@admin_user.id])

    finder = ->(ext_id) { ext_id == "ext-1" ? purchase1 : nil }

    logger_messages = []
    Purchase.stub(:find_by_external_id, finder) do
      Rails.logger.stub(:info, ->(msg) { logger_messages << msg }) do
        MassRefundForFraudJob.new.perform(@product.id, ["ext-1", "nonexistent"], @admin_user.id)
      end
    end

    assert purchase1.verify
    assert logger_messages.any? { |m| m =~ /Mass fraud refund completed for product #{@product.id}: 1 succeeded, 1 failed/ }
  end

  test "handles refund errors and continues processing" do
    purchase1 = Object.new
    purchase1.define_singleton_method(:link_id) { @link_id ||= nil }
    purchase1.instance_variable_set(:@link_id, @product.id)
    purchase1.define_singleton_method(:link_id) { @link_id }
    purchase1.define_singleton_method(:refund_for_fraud_and_block_buyer!) do |_admin_id|
      raise StandardError, "Refund failed"
    end

    purchase2 = Minitest::Mock.new
    purchase2.expect(:link_id, @product.id)
    purchase2.expect(:refund_for_fraud_and_block_buyer!, nil, [@admin_user.id])

    finder = ->(ext_id) { { "ext-1" => purchase1, "ext-2" => purchase2 }[ext_id] }

    notify_args = []
    event_stub = Object.new
    event_stub.define_singleton_method(:add_metadata) { |*_args, **_kwargs| nil }
    notifier = ->(error, &blk) { notify_args << error; blk&.call(event_stub) }

    logger_messages = []
    Purchase.stub(:find_by_external_id, finder) do
      ErrorNotifier.stub(:notify, notifier) do
        Rails.logger.stub(:info, ->(msg) { logger_messages << msg }) do
          Rails.logger.stub(:error, ->(*_) {}) do
            MassRefundForFraudJob.new.perform(@product.id, ["ext-1", "ext-2"], @admin_user.id)
          end
        end
      end
    end

    assert purchase2.verify
    assert_equal 1, notify_args.size
    assert_kind_of StandardError, notify_args.first
    assert logger_messages.any? { |m| m =~ /Mass fraud refund completed for product #{@product.id}: 1 succeeded, 1 failed/ }
  end
end
