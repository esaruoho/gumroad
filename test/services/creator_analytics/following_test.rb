# frozen_string_literal: true

require "test_helper"

class CreatorAnalytics::FollowingTest < ActiveSupport::TestCase
  setup do
    @user = users(:basic_user)
    @user.update_columns(timezone: "UTC")
    @service = CreatorAnalytics::Following.new(@user)
    @events = []
  end

  test "#by_date returns expected data" do
    add_event("added", Time.utc(2021, 1, 1))
    add_event("added", Time.utc(2021, 1, 1))
    add_event("removed", Time.utc(2021, 1, 1))
    add_event("added", Time.utc(2021, 1, 2))
    add_event("added", Time.utc(2021, 1, 2))
    add_event("removed", Time.utc(2021, 1, 2))
    add_event("added", Time.utc(2021, 1, 4))

    with_following_search do
      travel_to Time.utc(2021, 1, 4) do
        result = @service.by_date(start_date: Date.new(2021, 1, 2), end_date: Date.new(2021, 1, 4))

        assert_equal(
          {
            dates: ["Saturday, January 2nd", "Sunday, January 3rd", "Monday, January 4th"],
            by_date: {
              new_followers: [2, 0, 1],
              followers_removed: [1, 0, 0],
              totals: [2, 2, 3],
            },
            new_followers: 2,
            start_date: "Jan  2, 2021",
            end_date: "Today",
            first_follower_date: "Jan  1, 2021",
          },
          result
        )
      end
    end
  end

  test "#by_date returns expected data when the user has no followers" do
    with_following_search do
      result = @service.by_date(start_date: Date.new(2021, 1, 1), end_date: Date.new(2021, 1, 2))

      assert_equal(
        {
          dates: ["Friday, January 1st", "Saturday, January 2nd"],
          by_date: {
            new_followers: [0, 0],
            followers_removed: [0, 0],
            totals: [0, 0],
          },
          new_followers: 0,
          start_date: "Jan  1, 2021",
          end_date: "Jan  2, 2021",
          first_follower_date: nil,
        },
        result
      )
    end
  end

  test "#net_total returns net total of followers" do
    add_event("added", Time.utc(2021, 1, 1))
    add_event("added", Time.utc(2021, 1, 1))
    add_event("removed", Time.utc(2021, 1, 1))
    add_event("added", Time.utc(2021, 1, 2))
    add_event("added", Time.utc(2021, 1, 2))
    add_event("removed", Time.utc(2021, 1, 2))

    with_following_search do
      assert_equal 2, @service.net_total
    end
  end

  test "#net_total returns net total before a specific date" do
    add_event("added", Time.utc(2021, 1, 1))
    add_event("added", Time.utc(2021, 1, 2))
    add_event("removed", Time.utc(2021, 1, 3))

    with_following_search do
      assert_equal 1, @service.net_total(before_date: Date.new(2021, 1, 4))
      assert_equal 2, @service.net_total(before_date: Date.new(2021, 1, 3))
      assert_equal 1, @service.net_total(before_date: Date.new(2021, 1, 2))
      assert_equal 0, @service.net_total(before_date: Date.new(2021, 1, 1))
    end
  end

  test "#net_total supports time zones" do
    add_event("added", Time.utc(2021, 1, 2, 1))
    before_date = Date.new(2021, 1, 2)

    with_following_search do
      assert_equal 0, @service.net_total(before_date:)

      @user.update_columns(timezone: "Eastern Time (US & Canada)")
      assert_equal 1, @service.net_total(before_date:)
      assert_equal 1, @service.net_total
    end
  end

  test "#first_follower_date returns nil if there are no followers" do
    with_following_search do
      assert_nil @service.first_follower_date
    end
  end

  test "#first_follower_date returns the date of the first follower" do
    add_event("added", Time.utc(2021, 1, 1))
    add_event("added", Time.utc(2021, 3, 5))

    with_following_search do
      assert_equal Date.new(2021, 1, 1), @service.first_follower_date
    end
  end

  test "#first_follower_date supports time zones" do
    add_event("added", Time.utc(2021, 1, 1))
    @user.update_columns(timezone: "Eastern Time (US & Canada)")

    with_following_search do
      assert_equal Date.new(2020, 12, 31), @service.first_follower_date
    end
  end

  test "#counts returns followers added, removed, and running net total by day" do
    add_event("added", Time.utc(2021, 1, 1))
    add_event("added", Time.utc(2021, 1, 1))
    add_event("removed", Time.utc(2021, 1, 1))
    add_event("added", Time.utc(2021, 1, 2))
    add_event("added", Time.utc(2021, 1, 2))
    add_event("removed", Time.utc(2021, 1, 2))
    add_event("added", Time.utc(2021, 1, 4))

    with_following_search do
      assert_equal(
        {
          new_followers: [2, 2, 0, 1],
          followers_removed: [1, 1, 0, 0],
          totals: [1, 2, 2, 3],
        },
        @service.send(:counts, (Date.new(2021, 1, 1)..Date.new(2021, 1, 4)).to_a)
      )

      assert_equal(
        {
          new_followers: [0],
          followers_removed: [0],
          totals: [2],
        },
        @service.send(:counts, (Date.new(2021, 1, 3)..Date.new(2021, 1, 3)).to_a)
      )
    end
  end

  test "#counts attributes events near midnight during DST to the right day" do
    user = users(:another_seller)
    user.update_columns(timezone: "Pacific Time (US & Canada)")
    service = CreatorAnalytics::Following.new(user)
    add_event("added", Time.utc(2025, 7, 15, 7, 30), user:)

    with_following_search do
      result = service.send(:counts, [Date.new(2025, 7, 14), Date.new(2025, 7, 15)])

      assert_equal [0, 1], result[:new_followers]
    end
  end

  test "#counts buckets events across DST transition" do
    user = users(:another_seller)
    user.update_columns(timezone: "Pacific Time (US & Canada)")
    service = CreatorAnalytics::Following.new(user)
    add_event("added", Time.utc(2025, 3, 9, 7, 0), user:)
    add_event("added", Time.utc(2025, 3, 10, 8, 0), user:)

    with_following_search do
      result = service.send(:counts, (Date.new(2025, 3, 8)..Date.new(2025, 3, 10)).to_a)

      assert_equal [1, 0, 1], result[:new_followers]
    end
  end

  private
    FakeSearchResult = Struct.new(:aggregations, :results)
    FakeSource = Struct.new(:timestamp)
    FakeResult = Struct.new(:_source)

    class FakeEsObject
      def initialize(hash)
        @hash = hash
      end

      def [](key)
        wrap(@hash[key] || @hash[key.to_s] || @hash[key.to_sym])
      end

      def dig(*keys)
        keys.reduce(self) { |value, key| value.respond_to?(:[]) ? value[key] : nil }
      end

      def method_missing(name, *args, &block)
        value = self[name]
        return value unless value.nil?

        super
      end

      def respond_to_missing?(name, include_private = false)
        @hash.key?(name) || @hash.key?(name.to_s) || @hash.key?(name.to_sym) || super
      end

      private
        def wrap(value)
          case value
          when Hash
            FakeEsObject.new(value)
          when Array
            value.map { |item| item.is_a?(Hash) ? FakeEsObject.new(item) : item }
          else
            value
          end
        end
    end

    def add_event(name, timestamp, user: @user)
      @events << { followed_user_id: user.id, name:, timestamp: }
    end

    def with_following_search(&block)
      ConfirmedFollowerEvent.stub(:search, ->(body) { search_response(body) }, &block)
    end

    def search_response(body)
      matching_events = @events.select { _1[:followed_user_id] == followed_user_id_from(body) }

      if body[:sort]
        event = matching_events.min_by { _1[:timestamp] }
        return FakeSearchResult.new(FakeEsObject.new({}), event ? [FakeResult.new(FakeSource.new(event[:timestamp].iso8601))] : [])
      end

      matching_events = matching_events.select { |event| event_in_ranges?(event, body) }

      if body.dig(:aggs, :dates)
        buckets = matching_events
          .group_by { |event| event[:timestamp].in_time_zone(time_zone_from(body)).to_date }
          .sort_by { |date, _| date }
          .map do |date, events|
            counts = CreatorAnalytics::Following::ADDED_AND_REMOVED.index_with do |name|
              { count: { value: events.count { _1[:name] == name } } }
            end
            { "key_as_string" => date.to_s }.merge(counts)
          end

        FakeSearchResult.new(FakeEsObject.new(dates: { buckets: }), [])
      else
        counts = CreatorAnalytics::Following::ADDED_AND_REMOVED.index_with do |name|
          { count: { value: matching_events.count { _1[:name] == name } } }
        end
        FakeSearchResult.new(FakeEsObject.new(counts), [])
      end
    end

    def followed_user_id_from(body)
      body.dig(:query, :bool, :filter).find { _1.dig(:term, :followed_user_id) }.dig(:term, :followed_user_id)
    end

    def event_in_ranges?(event, body)
      Array.wrap(body.dig(:query, :bool, :must)).all? do |condition|
        range = condition&.dig(:range, :timestamp)
        next true if range.blank?

        after_start = range[:gte].blank? || event[:timestamp] >= Time.iso8601(range[:gte])
        before_end = range[:lt].blank? || event[:timestamp] < Time.iso8601(range[:lt])
        after_start && before_end
      end
    end

    def time_zone_from(body)
      body.dig(:aggs, :dates, :date_histogram, :time_zone)
    end
end
