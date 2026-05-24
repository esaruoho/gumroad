# frozen_string_literal: true

require "test_helper"

class CreatorAnalytics::Churn::DateWindowTest < ActiveSupport::TestCase
  def make_seller(timezone: "UTC", created_at: Time.utc(2020, 1, 1))
    user = User.new(
      email: "dw-#{SecureRandom.hex(4)}@example.com",
      timezone: timezone
    )
    user.save!(validate: false)
    user.update_columns(created_at: created_at, updated_at: created_at)
    user.reload
  end

  def fake_product_scope(seller, earliest_date)
    scope = CreatorAnalytics::Churn::ProductScope.new(seller: seller)
    scope.define_singleton_method(:earliest_analytics_date) { earliest_date }
    scope
  end

  def date_in_seller_timezone(time, seller)
    time.in_time_zone(seller.timezone).to_date
  end

  test "#initialize accepts Date objects" do
    seller = make_seller
    start_date = Date.new(2020, 1, 15)
    end_date = Date.new(2020, 1, 20)
    travel_to Time.utc(2020, 2, 1) do
      window = CreatorAnalytics::Churn::DateWindow.new(
        seller: seller,
        product_scope: fake_product_scope(seller, Date.new(2020, 1, 1)),
        start_date: start_date,
        end_date: end_date
      )
      assert_equal start_date, window.start_date
      assert_equal end_date, window.end_date
    end
  end

  test "#initialize converts Time objects to Date in seller's timezone" do
    seller = make_seller
    start_time = Time.utc(2020, 1, 15, 10, 30)
    end_time = Time.utc(2020, 1, 20, 14, 45)
    travel_to Time.utc(2020, 2, 1) do
      window = CreatorAnalytics::Churn::DateWindow.new(
        seller: seller,
        product_scope: fake_product_scope(seller, Date.new(2020, 1, 1)),
        start_date: start_time,
        end_date: end_time
      )
      assert_equal date_in_seller_timezone(start_time, seller), window.start_date
      assert_equal date_in_seller_timezone(end_time, seller), window.end_date
    end
  end

  test "#initialize parses string dates" do
    seller = make_seller
    travel_to Time.utc(2020, 2, 1) do
      window = CreatorAnalytics::Churn::DateWindow.new(
        seller: seller,
        product_scope: fake_product_scope(seller, Date.new(2020, 1, 1)),
        start_date: "2020-01-15",
        end_date: "2020-01-20"
      )
      assert_equal Date.parse("2020-01-15"), window.start_date
      assert_equal Date.parse("2020-01-20"), window.end_date
    end
  end

  test "#initialize uses default dates when nil supplied" do
    seller = make_seller
    travel_to Time.utc(2020, 2, 1) do
      today = Time.current.in_time_zone(seller.timezone).to_date
      window = CreatorAnalytics::Churn::DateWindow.new(
        seller: seller,
        product_scope: fake_product_scope(seller, today - 100),
        start_date: nil,
        end_date: nil
      )
      assert_equal today, window.end_date
      assert_equal today - CreatorAnalytics::Churn::DateWindow::DEFAULT_RANGE_DAYS, window.start_date
    end
  end

  test "#initialize raises InvalidDateRange for invalid types" do
    seller = make_seller
    assert_raises(CreatorAnalytics::Churn::InvalidDateRange) do
      CreatorAnalytics::Churn::DateWindow.new(
        seller: seller,
        product_scope: fake_product_scope(seller, Date.new(2020, 1, 1)),
        start_date: 12345,
        end_date: Date.new(2020, 1, 20)
      )
    end
  end

  test "#initialize raises InvalidDateRange for invalid string formats" do
    seller = make_seller
    assert_raises(CreatorAnalytics::Churn::InvalidDateRange) do
      CreatorAnalytics::Churn::DateWindow.new(
        seller: seller,
        product_scope: fake_product_scope(seller, Date.new(2020, 1, 1)),
        start_date: "not-a-date",
        end_date: Date.new(2020, 1, 20)
      )
    end
  end

  test "clamps start_date to earliest_analytics_date" do
    seller = make_seller
    earliest = Date.new(2020, 1, 10)
    travel_to Time.utc(2020, 2, 1) do
      window = CreatorAnalytics::Churn::DateWindow.new(
        seller: seller,
        product_scope: fake_product_scope(seller, earliest),
        start_date: Date.new(2020, 1, 1),
        end_date: Date.new(2020, 1, 20)
      )
      assert_equal earliest, window.start_date
      assert_equal Date.new(2020, 1, 20), window.end_date
    end
  end

  test "clamps end_date to today when after today" do
    seller = make_seller
    travel_to Time.utc(2020, 2, 1) do
      today = Time.current.in_time_zone(seller.timezone).to_date
      start_date = today - 10
      end_date = today + 5
      window = CreatorAnalytics::Churn::DateWindow.new(
        seller: seller,
        product_scope: fake_product_scope(seller, Date.new(2020, 1, 1)),
        start_date: start_date,
        end_date: end_date
      )
      assert_equal start_date, window.start_date
      assert_equal today, window.end_date
    end
  end

  test "clamps end_date to start_date when start_date is after end_date" do
    seller = make_seller
    start_date = Date.new(2020, 1, 20)
    end_date = Date.new(2020, 1, 15)
    travel_to Time.utc(2020, 2, 1) do
      window = CreatorAnalytics::Churn::DateWindow.new(
        seller: seller,
        product_scope: fake_product_scope(seller, Date.new(2020, 1, 1)),
        start_date: start_date,
        end_date: end_date
      )
      assert_equal start_date, window.start_date
      assert_equal start_date, window.end_date
    end
  end

  test "clamps start_date to seller created_at when seller has no sales" do
    seller_created_at = Time.utc(2020, 1, 1, 12, 0)
    seller = make_seller(created_at: seller_created_at)
    travel_to Time.utc(2020, 2, 1) do
      window = CreatorAnalytics::Churn::DateWindow.new(
        seller: seller,
        product_scope: fake_product_scope(seller, date_in_seller_timezone(seller_created_at, seller)),
        start_date: Date.new(2019, 12, 1),
        end_date: Date.new(2020, 1, 20)
      )
      assert_equal date_in_seller_timezone(seller_created_at, seller), window.start_date
      assert_equal Date.new(2020, 1, 20), window.end_date
    end
  end

  test "#timezone_id returns seller's timezone identifier" do
    seller = make_seller
    travel_to Time.utc(2020, 2, 1) do
      window = CreatorAnalytics::Churn::DateWindow.new(
        seller: seller,
        product_scope: fake_product_scope(seller, Date.new(2020, 1, 1)),
        start_date: Date.new(2020, 1, 15),
        end_date: Date.new(2020, 1, 20)
      )
      assert_equal seller.timezone_id, window.timezone_id
    end
  end

  test "#daily_dates returns an array of all dates in the range" do
    seller = make_seller
    travel_to Time.utc(2020, 2, 1) do
      window = CreatorAnalytics::Churn::DateWindow.new(
        seller: seller,
        product_scope: fake_product_scope(seller, Date.new(2020, 1, 1)),
        start_date: Date.new(2020, 1, 15),
        end_date: Date.new(2020, 1, 18)
      )
      assert_equal [Date.new(2020, 1, 15), Date.new(2020, 1, 16), Date.new(2020, 1, 17), Date.new(2020, 1, 18)],
                   window.daily_dates
    end
  end

  test "#monthly_dates returns first-of-month dates for each month in range" do
    seller = make_seller
    travel_to Time.utc(2020, 4, 1) do
      window = CreatorAnalytics::Churn::DateWindow.new(
        seller: seller,
        product_scope: fake_product_scope(seller, Date.new(2020, 1, 1)),
        start_date: Date.new(2020, 1, 15),
        end_date: Date.new(2020, 3, 10)
      )
      assert_equal [Date.new(2020, 1, 1), Date.new(2020, 2, 1), Date.new(2020, 3, 1)],
                   window.monthly_dates
    end
  end

  test "converts times to dates in seller's Pacific timezone" do
    seller = make_seller(timezone: "Pacific Time (US & Canada)")
    start_time = Time.utc(2020, 1, 15, 8, 0)
    end_time = Time.utc(2020, 1, 15, 16, 0)
    travel_to Time.utc(2020, 2, 1) do
      window = CreatorAnalytics::Churn::DateWindow.new(
        seller: seller,
        product_scope: fake_product_scope(seller, Date.new(2020, 1, 1)),
        start_date: start_time,
        end_date: end_time
      )
      assert_equal date_in_seller_timezone(start_time, seller), window.start_date
      assert_equal date_in_seller_timezone(end_time, seller), window.end_date
    end
  end
end
