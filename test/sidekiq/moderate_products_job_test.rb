# frozen_string_literal: true

require "test_helper"

class ModerateProductsJobTest < ActiveSupport::TestCase
  setup do
    @product1 = links(:named_seller_product)
    @product2 = links(:preorder_test_product)
  end

  def passed_result
    ContentModeration::ModerateRecordService::CheckResult.new(passed: true, reasons: [])
  end

  test "runs moderation for each product in the given ids" do
    calls = []
    ContentModeration::ModerateRecordService.stub(:check, ->(record, type) {
      calls << [record.id, type]
      passed_result
    }) do
      ModerateProductsJob.new.perform([@product1.id, @product2.id])
    end

    assert_includes calls, [@product1.id, :product]
    assert_includes calls, [@product2.id, :product]
  end

  test "skips ids that no longer exist without raising" do
    missing_id = Link.maximum(:id).to_i + 10_000
    calls = []
    ContentModeration::ModerateRecordService.stub(:check, ->(record, type) {
      calls << record.id
      passed_result
    }) do
      assert_nothing_raised do
        ModerateProductsJob.new.perform([@product1.id, missing_id])
      end
    end

    assert_equal 1, calls.size
  end

  test "reports errors for individual products and continues processing the rest" do
    p1_id = @product1.id
    p2_id = @product2.id
    seen = []
    check_stub = ->(record, _type) do
      if record.id == p1_id
        raise Faraday::TimeoutError.new("Net::ReadTimeout")
      else
        seen << record.id
        passed_result
      end
    end

    notify_args = []
    notifier_stub = ->(error, context: nil) { notify_args << [error, context] }

    ContentModeration::ModerateRecordService.stub(:check, check_stub) do
      ErrorNotifier.stub(:notify, notifier_stub) do
        Rails.logger.stub(:error, ->(*_) {}) do
          ModerateProductsJob.new.perform([p1_id, p2_id])
        end
      end
    end

    assert_equal 1, notify_args.size
    error, context = notify_args.first
    assert_kind_of Faraday::TimeoutError, error
    assert_equal({ product_id: p1_id }, context)
    assert_includes seen, p2_id
  end

  test "enqueues to the low queue" do
    assert_equal "low", ModerateProductsJob.sidekiq_options["queue"].to_s
  end
end
