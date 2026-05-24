# frozen_string_literal: true

require "test_helper"

class RegenerateCreatorAnalyticsCacheWorkerTest < ActiveSupport::TestCase
  test "runs CreatorAnalytics::CachingProxy#overwrite_cache for date/state/referral" do
    user = users(:named_seller)
    seen_user = nil
    calls = []

    fake_service = Object.new
    fake_service.define_singleton_method(:overwrite_cache) { |date, by:| calls << [date, by] }

    CreatorAnalytics::CachingProxy.stub(:new, ->(u) { seen_user = u; fake_service }) do
      RegenerateCreatorAnalyticsCacheWorker.new.perform(user.id, "2020-07-05")
    end

    assert_equal user, seen_user
    expected = [[Date.new(2020, 7, 5), :date], [Date.new(2020, 7, 5), :state], [Date.new(2020, 7, 5), :referral]]
    assert_equal expected, calls
  end
end
