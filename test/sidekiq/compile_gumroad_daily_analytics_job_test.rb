# frozen_string_literal: true

require "test_helper"

class CompileGumroadDailyAnalyticsJobTest < ActiveSupport::TestCase
  # The worker iterates `(Date.today - REFRESH_PERIOD..Date.today)` and calls
  # `GumroadDailyAnalytic.import(date)` for each day. Rather than seed time-windowed
  # purchase fixtures (the original RSpec did this with 6+ FactoryBot rows that the
  # 43-row purchases fixture can't express), assert the iteration shape by
  # intercepting `.import` at the class level and recording invocations.

  setup do
    @original_import = GumroadDailyAnalytic.method(:import)
    @import_calls = []
    calls = @import_calls
    GumroadDailyAnalytic.define_singleton_method(:import) { |date| calls << date }
  end

  teardown do
    GumroadDailyAnalytic.singleton_class.send(:remove_method, :import)
    GumroadDailyAnalytic.define_singleton_method(:import, @original_import) if @original_import
  end

  test "#perform invokes GumroadDailyAnalytic.import for each day in REFRESH_PERIOD up to today" do
    travel_to Time.zone.local(2024, 6, 15, 12, 0, 0) do
      CompileGumroadDailyAnalyticsJob.new.perform
    end

    # REFRESH_PERIOD is 45.days; range is inclusive on both ends → 46 iterations.
    assert_equal 46, @import_calls.size
    assert_equal Date.new(2024, 5, 1), @import_calls.first
    assert_equal Date.new(2024, 6, 15), @import_calls.last
  end

  test "#perform passes Date objects (not Time) to import" do
    travel_to Time.zone.local(2024, 1, 10, 0, 0, 0) do
      CompileGumroadDailyAnalyticsJob.new.perform
    end

    assert @import_calls.all? { |d| d.is_a?(Date) && !d.is_a?(DateTime) }
  end
end
