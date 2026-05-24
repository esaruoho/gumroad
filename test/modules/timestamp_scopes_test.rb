# frozen_string_literal: true

require "test_helper"

class TimestampScopesTest < ActiveSupport::TestCase
  setup do
    @purchase = purchases(:named_seller_call_purchase)
    @purchase.update_column(:created_at, Time.utc(2020, 3, 9, 6, 30))
  end

  test ".created_between returns records matching range" do
    assert_equal [], Purchase.created_between(Time.utc(2020, 3, 3)..Time.utc(2020, 3, 6)).to_a
    assert_equal [], Purchase.created_between(Date.new(2020, 3, 3)..Date.new(2020, 3, 6)).to_a

    assert_equal [@purchase], Purchase.created_between(Time.utc(2020, 3, 5)..Time.utc(2020, 3, 10)).to_a
    assert_equal [@purchase], Purchase.created_between(Date.new(2020, 3, 5)..Date.new(2020, 3, 10)).to_a
  end

  test ".column_between_with_offset returns records matching range and offset" do
    assert_equal [], Purchase.column_between_with_offset("created_at", Date.new(2020, 3, 8)..Date.new(2020, 3, 8), "+00:00").to_a
    assert_equal [@purchase], Purchase.column_between_with_offset("created_at", Date.new(2020, 3, 9)..Date.new(2020, 3, 9), "+00:00").to_a
    assert_equal [@purchase], Purchase.column_between_with_offset("created_at", Date.new(2020, 3, 8)..Date.new(2020, 3, 8), "-07:00").to_a
  end

  test ".created_at_between_with_offset returns records within range and offset" do
    assert_equal [], Purchase.created_at_between_with_offset(Date.new(2020, 3, 8)..Date.new(2020, 3, 8), "+00:00").to_a
    assert_equal [@purchase], Purchase.created_at_between_with_offset(Date.new(2020, 3, 9)..Date.new(2020, 3, 9), "+00:00").to_a
    assert_equal [@purchase], Purchase.created_at_between_with_offset(Date.new(2020, 3, 8)..Date.new(2020, 3, 8), "-07:00").to_a
  end

  test ".created_between_dates_in_timezone returns records matching range" do
    assert_equal [@purchase], Purchase.created_between_dates_in_timezone(Date.new(2020, 3, 8)..Date.new(2020, 3, 8), "America/Los_Angeles").to_a
    assert_equal [], Purchase.created_between_dates_in_timezone(Date.new(2020, 3, 8)..Date.new(2020, 3, 8), "UTC").to_a
  end

  test ".created_before_end_of_date_in_timezone returns records matching date" do
    # Scope by created_at range so we don't include the other fixture purchases (created at Time.current).
    range = Time.utc(2020, 1, 1)..Time.utc(2020, 12, 31)
    assert_equal [@purchase], Purchase.created_before_end_of_date_in_timezone(Date.new(2020, 3, 8), "America/Los_Angeles").where(created_at: range).to_a
    assert_equal [@purchase], Purchase.created_before_end_of_date_in_timezone(Date.new(2020, 3, 9), "America/Los_Angeles").where(created_at: range).to_a
    assert_equal [], Purchase.created_before_end_of_date_in_timezone(Date.new(2020, 3, 8), "UTC").where(created_at: range).to_a
    assert_equal [@purchase], Purchase.created_before_end_of_date_in_timezone(Date.new(2020, 3, 9), "UTC").where(created_at: range).to_a
  end

  test ".created_on_or_after_start_of_date_in_timezone returns records matching date" do
    range = Time.utc(2020, 1, 1)..Time.utc(2020, 12, 31)
    assert_equal [@purchase], Purchase.created_on_or_after_start_of_date_in_timezone(Date.new(2020, 3, 8), "America/Los_Angeles").where(created_at: range).to_a
    assert_equal [@purchase], Purchase.created_on_or_after_start_of_date_in_timezone(Date.new(2020, 3, 8), "UTC").where(created_at: range).to_a
    assert_equal [@purchase], Purchase.created_on_or_after_start_of_date_in_timezone(Date.new(2020, 3, 9), "UTC").where(created_at: range).to_a
    assert_equal [], Purchase.created_on_or_after_start_of_date_in_timezone(Date.new(2020, 3, 10), "UTC").where(created_at: range).to_a
  end
end
