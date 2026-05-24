# frozen_string_literal: true

require "test_helper"

class CreatorAnalytics::Churn::DatasetBuilderTest < ActiveSupport::TestCase
  setup do
    @seller = users(:basic_user)
    @seller.update_columns(timezone: "UTC", created_at: Time.utc(2020, 1, 1))

    @product1 = Link.new(
      user: @seller,
      name: "Product Alpha",
      unique_permalink: "alphap",
      price_cents: 100,
      native_type: "membership",
      is_recurring_billing: true,
      subscription_duration: :monthly,
    )
    @product1.save!(validate: false)
    Price.create!(link: @product1, price_cents: 100, currency: "usd", recurrence: "monthly")

    @product2 = Link.new(
      user: @seller,
      name: "Product Beta",
      unique_permalink: "betap",
      price_cents: 100,
      native_type: "membership",
      is_recurring_billing: true,
      subscription_duration: :monthly,
    )
    @product2.save!(validate: false)
    Price.create!(link: @product2, price_cents: 100, currency: "usd", recurrence: "monthly")

    # Create purchases with early dates to ensure earliest_analytics_date is set correctly
    p1_purchase = Purchase.new(
      link: @product1,
      seller: @seller, email: "buyer-a@example.com", price_cents: 100,
      total_transaction_cents: 100, displayed_price_cents: 100,
      displayed_price_currency_type: "usd",
      purchase_state: "successful", succeeded_at: Time.current,
      created_at: Date.new(2020, 1, 1).to_time
    )
    p1_purchase.save(validate: false)

    p2_purchase = Purchase.new(
      link: @product2,
      seller: @seller, email: "buyer-b@example.com", price_cents: 100,
      total_transaction_cents: 100, displayed_price_cents: 100,
      displayed_price_currency_type: "usd",
      purchase_state: "successful", succeeded_at: Time.current,
      created_at: Date.new(2020, 1, 1).to_time
    )
    p2_purchase.save(validate: false)

    @start_date = Date.new(2020, 1, 15)
    @end_date = Date.new(2020, 1, 20)
    @product_scope = CreatorAnalytics::Churn::ProductScope.new(seller: @seller)
    @date_window = CreatorAnalytics::Churn::DateWindow.new(
      seller: @seller, product_scope: @product_scope,
      start_date: @start_date, end_date: @end_date
    )
  end

  PRODUCT_ZERO_STATS = { churn_rate: 0.0, churned_customers_count: 0, revenue_lost_cents: 0, subscriber_base: 0 }.freeze

  def build_service(churn_events: {}, new_subscriptions: {}, initial_active_counts: {}, date_window: @date_window)
    CreatorAnalytics::Churn::DatasetBuilder.new(
      product_scope: @product_scope,
      date_window: date_window,
      churn_events: churn_events,
      new_subscriptions: new_subscriptions,
      initial_active_counts: initial_active_counts,
    )
  end

  # ----- empty data context -----

  test "with empty data returns structure with empty daily, monthly, and summary data" do
    result = build_service.build

    assert result.key?(:metadata)
    assert result.key?(:data)
    assert result[:data].key?(:daily)
    assert result[:data].key?(:monthly)
    assert result[:data].key?(:summary)

    assert_kind_of Hash, result[:data][:daily]
    assert_kind_of Hash, result[:data][:monthly]
    assert result[:data][:summary].key?(:total)
    assert result[:data][:summary].key?(:by_product)

    @date_window.daily_dates.each do |date|
      day_key = date.to_s
      daily_entry = result[:data][:daily][day_key]
      assert daily_entry.key?(:by_product)
      assert daily_entry.key?(:total)
      assert_equal PRODUCT_ZERO_STATS, daily_entry[:total]
      daily_entry[:by_product].each_value do |stats|
        assert_equal PRODUCT_ZERO_STATS, stats
      end
    end

    @date_window.monthly_dates.each do |month_date|
      month_key = month_date.to_s
      monthly_entry = result[:data][:monthly][month_key]
      assert monthly_entry.key?(:by_product)
      assert monthly_entry.key?(:total)
      assert_equal PRODUCT_ZERO_STATS, monthly_entry[:total]
      monthly_entry[:by_product].each_value do |stats|
        assert_equal PRODUCT_ZERO_STATS, stats
      end
    end

    assert_equal PRODUCT_ZERO_STATS, result[:data][:summary][:total]
    assert_kind_of Hash, result[:data][:summary][:by_product]
    result[:data][:summary][:by_product].each_value do |stats|
      assert_equal PRODUCT_ZERO_STATS, stats
    end
  end

  test "with empty data includes metadata with date range and products" do
    result = build_service.build
    assert_equal "2020-01-15", result[:metadata][:start_date]
    assert_equal "2020-01-20", result[:metadata][:end_date]
    assert_kind_of Array, result[:metadata][:products]
    assert_equal 2, result[:metadata][:products].length
  end

  test "with empty data includes product info in metadata" do
    result = build_service.build
    product_info = result[:metadata][:products].find { |p| p[:name] == "Product Alpha" }
    assert_equal @product1.external_id, product_info[:external_id]
    assert_equal @product1.unique_permalink, product_info[:permalink]
    assert_equal "Product Alpha", product_info[:name]
  end

  test "with empty data returns zero stats for all daily entries" do
    result = build_service.build
    @date_window.daily_dates.each do |date|
      day_key = date.to_s
      assert result[:data][:daily][day_key].key?(:total)
      assert_equal PRODUCT_ZERO_STATS, result[:data][:daily][day_key][:total]
    end
  end

  # ----- with churn events and new subscriptions -----

  def churn_context_service
    churn_events = {
      [@product1.id, Date.new(2020, 1, 15)] => { churned_count: 2, revenue_lost_cents: 5000 },
      [@product1.id, Date.new(2020, 1, 16)] => { churned_count: 1, revenue_lost_cents: 3000 },
      [@product2.id, Date.new(2020, 1, 15)] => { churned_count: 3, revenue_lost_cents: 7500 }
    }
    new_subscriptions = {
      [@product1.id, Date.new(2020, 1, 15)] => 5,
      [@product1.id, Date.new(2020, 1, 16)] => 3,
      [@product2.id, Date.new(2020, 1, 15)] => 2
    }
    initial_active_counts = { @product1.id => 10, @product2.id => 5 }
    build_service(churn_events: churn_events, new_subscriptions: new_subscriptions, initial_active_counts: initial_active_counts)
  end

  test "calculates daily churn rates correctly" do
    result = churn_context_service.build
    day1 = result[:data][:daily]["2020-01-15"]

    p1 = day1[:by_product][@product1.unique_permalink]
    assert_equal 13.33, p1[:churn_rate]
    assert_equal 2, p1[:churned_customers_count]
    assert_equal 5000, p1[:revenue_lost_cents]
    assert_equal 15, p1[:subscriber_base]

    p2 = day1[:by_product][@product2.unique_permalink]
    assert_equal 42.86, p2[:churn_rate]
    assert_equal 3, p2[:churned_customers_count]
    assert_equal 7500, p2[:revenue_lost_cents]
    assert_equal 7, p2[:subscriber_base]

    total = day1[:total]
    assert_equal 22.73, total[:churn_rate]
    assert_equal 5, total[:churned_customers_count]
    assert_equal 12500, total[:revenue_lost_cents]
    assert_equal 22, total[:subscriber_base]
  end

  test "tracks running active counts across days" do
    result = churn_context_service.build
    day2 = result[:data][:daily]["2020-01-16"]
    assert_equal 16, day2[:by_product][@product1.unique_permalink][:subscriber_base]
  end

  test "prevents negative active counts" do
    service = build_service(
      churn_events: { [@product1.id, Date.new(2020, 1, 15)] => { churned_count: 20, revenue_lost_cents: 50000 } },
      new_subscriptions: { [@product1.id, Date.new(2020, 1, 15)] => 5 },
      initial_active_counts: { @product1.id => 10 },
    )
    result = service.build
    day2 = result[:data][:daily]["2020-01-16"]
    assert_operator day2[:by_product][@product1.unique_permalink][:subscriber_base], :>=, 0
  end

  test "calculates monthly aggregates correctly" do
    result = churn_context_service.build
    january = result[:data][:monthly]["2020-01-01"]
    assert january.key?(:by_product)
    assert january.key?(:total)

    p1m = january[:by_product][@product1.unique_permalink]
    assert_equal 18, p1m[:subscriber_base]
    assert_equal 3, p1m[:churned_customers_count]
    assert_equal 16.67, p1m[:churn_rate]

    assert_equal 25, january[:total][:subscriber_base]
    assert_equal 6, january[:total][:churned_customers_count]
  end

  test "uses Stripe formula: (churned / (active_base + new_subscribers)) * 100" do
    result = churn_context_service.build
    p1 = result[:data][:daily]["2020-01-15"][:by_product][@product1.unique_permalink]
    active_base = 10
    new_subscribers = 5
    churned = 2
    expected_rate = ((churned.to_f / (active_base + new_subscribers)) * 100).round(2)
    assert_equal expected_rate, p1[:churn_rate]
    assert_equal active_base + new_subscribers, p1[:subscriber_base]
  end

  test "sums monthly counts before calculating rate" do
    result = churn_context_service.build
    p1m = result[:data][:monthly]["2020-01-01"][:by_product][@product1.unique_permalink]
    expected_rate = ((3.0 / 18) * 100).round(2)
    assert_equal expected_rate, p1m[:churn_rate]
    refute_equal 9.79, p1m[:churn_rate]
  end

  test "calculates summary totals correctly" do
    result = churn_context_service.build
    summary = result[:data][:summary]
    p1s = summary[:by_product][@product1.unique_permalink]
    assert_equal 18, p1s[:subscriber_base]
    assert_equal 3, p1s[:churned_customers_count]
    assert_equal 8000, p1s[:revenue_lost_cents]
    assert_equal 16.67, p1s[:churn_rate]

    assert_equal 25, summary[:total][:subscriber_base]
    assert_equal 6, summary[:total][:churned_customers_count]
    assert_equal 15500, summary[:total][:revenue_lost_cents]
    assert_equal 24.0, summary[:total][:churn_rate]
  end

  test "handles products with no activity" do
    product3 = Link.new(
      user: @seller,
      name: "Product Gamma",
      unique_permalink: "gammap",
      price_cents: 100,
      native_type: "membership",
      is_recurring_billing: true,
      subscription_duration: :monthly,
    )
    product3.save!(validate: false)
    Price.create!(link: product3, price_cents: 100, currency: "usd", recurrence: "monthly")
    p3_purchase = Purchase.new(
      link: product3,
      seller: @seller, email: "buyer-c@example.com", price_cents: 100,
      total_transaction_cents: 100, displayed_price_cents: 100,
      displayed_price_currency_type: "usd",
      purchase_state: "successful", succeeded_at: Time.current
    )
    p3_purchase.save(validate: false)

    result = churn_context_service.build
    product3_info = result[:metadata][:products].find { |p| p[:name] == "Product Gamma" }
    assert product3_info.present?
    p3s = result[:data][:summary][:by_product][product3.unique_permalink]
    assert_equal PRODUCT_ZERO_STATS, p3s
  end

  # ----- with zero denominator -----

  test "returns zero churn rate when denominator is zero" do
    service = build_service(
      churn_events: { [@product1.id, Date.new(2020, 1, 15)] => { churned_count: 5, revenue_lost_cents: 10000 } },
      new_subscriptions: {},
      initial_active_counts: {},
    )
    result = service.build
    day1 = result[:data][:daily]["2020-01-15"]
    assert_equal 0.0, day1[:by_product][@product1.unique_permalink][:churn_rate]
    assert_equal 0.0, day1[:total][:churn_rate]
  end

  test "handles new subscriptions without churn" do
    service = build_service(
      churn_events: {},
      new_subscriptions: { [@product1.id, Date.new(2020, 1, 15)] => 10 },
      initial_active_counts: { @product1.id => 5 },
    )
    result = service.build
    day1 = result[:data][:daily]["2020-01-15"]
    assert_equal 0.0, day1[:by_product][@product1.unique_permalink][:churn_rate]
    assert_equal 15, day1[:by_product][@product1.unique_permalink][:subscriber_base]
  end

  # ----- with multiple months -----

  test "groups monthly data by month" do
    dw = CreatorAnalytics::Churn::DateWindow.new(
      seller: @seller, product_scope: @product_scope,
      start_date: Date.new(2020, 1, 15), end_date: Date.new(2020, 2, 5)
    )
    service = build_service(
      churn_events: {
        [@product1.id, Date.new(2020, 1, 20)] => { churned_count: 2, revenue_lost_cents: 5000 },
        [@product1.id, Date.new(2020, 2, 1)] => { churned_count: 1, revenue_lost_cents: 3000 },
      },
      new_subscriptions: {
        [@product1.id, Date.new(2020, 1, 20)] => 5,
        [@product1.id, Date.new(2020, 2, 1)] => 3,
      },
      initial_active_counts: { @product1.id => 10 },
      date_window: dw,
    )
    result = service.build

    assert result[:data][:monthly].key?("2020-01-01")
    assert result[:data][:monthly].key?("2020-02-01")
    january = result[:data][:monthly]["2020-01-01"]
    assert_equal 2, january[:by_product][@product1.unique_permalink][:churned_customers_count]
    assert_equal 15, january[:by_product][@product1.unique_permalink][:subscriber_base]
    february = result[:data][:monthly]["2020-02-01"]
    assert_equal 1, february[:by_product][@product1.unique_permalink][:churned_customers_count]
    assert_equal 16, february[:by_product][@product1.unique_permalink][:subscriber_base]
  end

  test "tracks subscriber_base per month correctly" do
    dw = CreatorAnalytics::Churn::DateWindow.new(
      seller: @seller, product_scope: @product_scope,
      start_date: Date.new(2020, 1, 15), end_date: Date.new(2020, 2, 5)
    )
    service = build_service(
      churn_events: {
        [@product1.id, Date.new(2020, 1, 20)] => { churned_count: 2, revenue_lost_cents: 5000 },
        [@product1.id, Date.new(2020, 2, 1)] => { churned_count: 1, revenue_lost_cents: 3000 },
      },
      new_subscriptions: {
        [@product1.id, Date.new(2020, 1, 20)] => 5,
        [@product1.id, Date.new(2020, 2, 1)] => 3,
      },
      initial_active_counts: { @product1.id => 10 },
      date_window: dw,
    )
    result = service.build
    assert_equal 15, result[:data][:monthly]["2020-01-01"][:by_product][@product1.unique_permalink][:subscriber_base]
    assert_equal 16, result[:data][:monthly]["2020-02-01"][:by_product][@product1.unique_permalink][:subscriber_base]
  end

  # ----- with rounding -----

  test "rounds churn rates to 2 decimal places" do
    service = build_service(
      churn_events: { [@product1.id, Date.new(2020, 1, 15)] => { churned_count: 1, revenue_lost_cents: 2000 } },
      new_subscriptions: { [@product1.id, Date.new(2020, 1, 15)] => 3 },
      initial_active_counts: { @product1.id => 3 },
    )
    result = service.build
    day1 = result[:data][:daily]["2020-01-15"]
    assert_equal 16.67, day1[:by_product][@product1.unique_permalink][:churn_rate]
  end
end
