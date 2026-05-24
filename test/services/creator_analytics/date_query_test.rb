# frozen_string_literal: true

require "test_helper"

class CreatorAnalytics::DateQueryTest < ActiveSupport::TestCase
  test "day_range builds explicit datetime bounds for dates with a midnight DST gap" do
    result = CreatorAnalytics::DateQuery.day_range(
      field: :timestamp,
      start_date: Date.new(2026, 3, 22),
      end_date: Date.new(2026, 3, 22),
      timezone: "Tehran"
    )

    assert_equal(
      {
        range: {
          timestamp: {
            gte: Date.new(2026, 3, 22).in_time_zone("Tehran").iso8601,
            lt: Date.new(2026, 3, 23).in_time_zone("Tehran").iso8601,
          }
        }
      },
      result
    )
    refute result.dig(:range, :timestamp).key?(:time_zone)
  end

  test "before_day builds an explicit start-of-day instant for exclusive upper bounds" do
    result = CreatorAnalytics::DateQuery.before_day(field: :created_at, date: Date.new(2026, 3, 22), timezone: "Tehran")

    assert_equal(
      {
        range: {
          created_at: {
            lt: Date.new(2026, 3, 22).in_time_zone("Tehran").iso8601,
          }
        }
      },
      result
    )
  end
end
