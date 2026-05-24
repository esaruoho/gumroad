# frozen_string_literal: true

require "test_helper"

class ModerateProductsJobTest < ActiveSupport::TestCase
  setup do
    @product1 = links(:named_seller_product)
    @product2 = links(:basic_user_product)

    @passed_result = ContentModeration::ModerateRecordService::CheckResult.new(passed: true, reasons: [])
    @check_calls = []
    @check_behavior = ->(_record, _kind) { @passed_result }

    behavior = @check_calls
    capture = ->(record, kind) {
      behavior << [record.id, kind]
      @check_behavior.call(record, kind)
    }
    @capture = capture

    ContentModeration::ModerateRecordService.singleton_class.alias_method(:_orig_check, :check)
    ContentModeration::ModerateRecordService.define_singleton_method(:check) { |record, kind| capture.call(record, kind) }
  end

  teardown do
    if ContentModeration::ModerateRecordService.singleton_class.method_defined?(:_orig_check) ||
       ContentModeration::ModerateRecordService.singleton_class.private_method_defined?(:_orig_check)
      ContentModeration::ModerateRecordService.singleton_class.alias_method(:check, :_orig_check)
      ContentModeration::ModerateRecordService.singleton_class.remove_method(:_orig_check)
    end
  end

  test "runs moderation for each product in the given ids" do
    ModerateProductsJob.new.perform([@product1.id, @product2.id])

    assert_includes @check_calls, [@product1.id, :product]
    assert_includes @check_calls, [@product2.id, :product]
  end

  test "skips ids that no longer exist without raising" do
    missing_id = Link.maximum(:id).to_i + 10_000

    assert_nothing_raised do
      ModerateProductsJob.new.perform([@product1.id, missing_id])
    end

    assert_equal 1, @check_calls.size
  end

  test "reports errors for individual products and continues processing the rest" do
    product1_id = @product1.id
    @check_behavior = ->(record, _kind) {
      raise Faraday::TimeoutError, "Net::ReadTimeout" if record.id == product1_id
      @passed_result
    }
    notified = []
    err_mod = Module.new
    err_mod.send(:define_method, :notify) { |err, context: nil| notified << [err.class, context] }
    ErrorNotifier.singleton_class.prepend(err_mod)

    ModerateProductsJob.new.perform([@product1.id, @product2.id])

    assert_includes notified, [Faraday::TimeoutError, { product_id: @product1.id }]
    assert_includes @check_calls, [@product2.id, :product]
  end

  test "enqueues to the low queue" do
    assert_equal :low, ModerateProductsJob.sidekiq_options["queue"]
  end
end
