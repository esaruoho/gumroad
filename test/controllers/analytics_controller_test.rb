# frozen_string_literal: true

require "test_helper"

class AnalyticsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @admin = users(:admin_for_named_seller)
    sign_in_as_seller(@admin, @seller)
  end

  teardown do
    restore_protect_against_forgery!
    if CreatorAnalytics::CachingProxy.method_defined?(:__orig_data_for_dates)
      CreatorAnalytics::CachingProxy.define_method(:data_for_dates, CreatorAnalytics::CachingProxy.instance_method(:__orig_data_for_dates))
      CreatorAnalytics::CachingProxy.remove_method(:__orig_data_for_dates)
    end
  end

  def stub_data_for_dates(captured)
    orig = CreatorAnalytics::CachingProxy.instance_method(:data_for_dates)
    CreatorAnalytics::CachingProxy.define_method(:__orig_data_for_dates, orig)
    CreatorAnalytics::CachingProxy.define_method(:data_for_dates) do |start_date, end_date, by:|
      captured << [start_date, end_date, by]
      { data: "data" }
    end
  end

  test "GET data_by_state clamps the date range to MAX_DATE_RANGE_DAYS days" do
    captured = []
    stub_data_for_dates(captured)
    get :data_by_state, params: { start_time: "Mon Jan 01 2024 00:00:00 GMT-0000", end_time: "Tue Dec 31 2025 00:00:00 GMT-0000" }
    assert_equal [Date.new(2025, 12, 31) - AnalyticsController::MAX_DATE_RANGE_DAYS.days, Date.new(2025, 12, 31), :state], captured.first
  end

  test "GET data_by_state does not clamp the date range when within the limit" do
    captured = []
    stub_data_for_dates(captured)
    get :data_by_state, params: { start_time: "Mon Jun 01 2025 00:00:00 GMT-0000", end_time: "Wed Jul 30 2025 00:00:00 GMT-0000" }
    assert_equal [Date.new(2025, 6, 1), Date.new(2025, 7, 30), :state], captured.first
  end

  test "GET data_by_referral clamps the date range" do
    captured = []
    stub_data_for_dates(captured)
    get :data_by_referral, params: { start_time: "Mon Jan 01 2024 00:00:00 GMT-0000", end_time: "Tue Dec 31 2025 00:00:00 GMT-0000" }
    assert_equal [Date.new(2025, 12, 31) - AnalyticsController::MAX_DATE_RANGE_DAYS.days, Date.new(2025, 12, 31), :referral], captured.first
  end

  test "GET data_by_referral does not clamp within the limit" do
    captured = []
    stub_data_for_dates(captured)
    get :data_by_referral, params: { start_time: "Mon Jun 01 2025 00:00:00 GMT-0000", end_time: "Wed Jul 30 2025 00:00:00 GMT-0000" }
    assert_equal [Date.new(2025, 6, 1), Date.new(2025, 7, 30), :referral], captured.first
  end

  test "GET data_by_date returns stats for start_time to end_time" do
    captured = []
    stub_data_for_dates(captured)
    start_time = "Mon Apr 8 2013 22:40:18 GMT-0700 (PDT)"
    end_time = "Wed Apr 10 2013 22:40:18 GMT-0700 (PDT)"
    get :data_by_date, params: { start_time:, end_time: }
    assert_equal({ data: "data" }.to_json, @response.body)
    assert_equal [Date.parse(start_time), Date.parse(end_time), :date], captured.first
  end

  test "GET data_by_date with invalid times uses last 29 days" do
    captured = []
    stub_data_for_dates(captured)
    travel_to Time.utc(2025, 6, 15) do
      get :data_by_date
      assert_equal [Date.current.ago(29.days), Date.current, :date], captured.first
    end
  end
end
