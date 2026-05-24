# frozen_string_literal: true

require "test_helper"

class GumroadDailyAnalyticsCompilerTest < ActiveSupport::TestCase
  DISCOVER_RECOMMENDED_FLAG = 1 << 8

  test ".compile_gumroad_price_cents aggregates data for the dates provided" do
    insert_purchase!(created_at: Time.utc(2023, 1, 4))
    insert_purchase!(created_at: Time.utc(2023, 1, 5))
    insert_purchase!(created_at: Time.utc(2023, 1, 6))
    insert_purchase!(created_at: Time.utc(2023, 1, 7))
    insert_purchase!(created_at: Time.utc(2023, 1, 8))

    range = Time.utc(2023, 1, 5)..Time.utc(2023, 1, 7)

    assert_equal 300, GumroadDailyAnalyticsCompiler.compile_gumroad_price_cents(between: range)
  end

  test ".compile_gumroad_price_cents aggregates purchase amounts" do
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 100)
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 200)
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 300)

    range = Time.utc(2023, 1, 5)..Time.utc(2023, 1, 5)

    assert_equal 600, GumroadDailyAnalyticsCompiler.compile_gumroad_price_cents(between: range)
  end

  test ".compile_gumroad_price_cents ignores unsuccessful purchases" do
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 100)
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 200, purchase_state: "failed")
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 300, purchase_state: "in_progress")

    range = Time.utc(2023, 1, 5)..Time.utc(2023, 1, 5)

    assert_equal 100, GumroadDailyAnalyticsCompiler.compile_gumroad_price_cents(between: range)
  end

  test ".compile_gumroad_price_cents ignores refunded purchases" do
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 100)
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 200, stripe_refunded: true)
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 300)

    range = Time.utc(2023, 1, 5)..Time.utc(2023, 1, 5)

    assert_equal 400, GumroadDailyAnalyticsCompiler.compile_gumroad_price_cents(between: range)
  end

  test ".compile_gumroad_fee_cents aggregates data for the dates provided" do
    insert_purchase!(created_at: Time.utc(2023, 1, 4))
    insert_purchase!(created_at: Time.utc(2023, 1, 5))
    insert_purchase!(created_at: Time.utc(2023, 1, 6))
    insert_purchase!(created_at: Time.utc(2023, 1, 7))
    insert_purchase!(created_at: Time.utc(2023, 1, 8))

    range = Time.utc(2023, 1, 5)..Time.utc(2023, 1, 7)

    assert_equal 30, GumroadDailyAnalyticsCompiler.compile_gumroad_fee_cents(between: range)
  end

  test ".compile_gumroad_fee_cents aggregates both purchase fees and service charges" do
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 100)
    insert_service_charge!(created_at: Time.utc(2023, 1, 5), charge_cents: 20)

    range = Time.utc(2023, 1, 5)..Time.utc(2023, 1, 5)

    assert_equal 30, GumroadDailyAnalyticsCompiler.compile_gumroad_fee_cents(between: range)
  end

  test ".compile_gumroad_fee_cents aggregates purchase fees" do
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 100)
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 200)
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 300)

    range = Time.utc(2023, 1, 5)..Time.utc(2023, 1, 5)

    assert_equal 60, GumroadDailyAnalyticsCompiler.compile_gumroad_fee_cents(between: range)
  end

  test ".compile_gumroad_fee_cents ignores unsuccessful purchases" do
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 100)
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 200, purchase_state: "failed")
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 300, purchase_state: "in_progress")

    range = Time.utc(2023, 1, 5)..Time.utc(2023, 1, 5)

    assert_equal 10, GumroadDailyAnalyticsCompiler.compile_gumroad_fee_cents(between: range)
  end

  test ".compile_gumroad_fee_cents ignores refunded purchases" do
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 100)
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 200, stripe_refunded: true)
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 300)

    range = Time.utc(2023, 1, 5)..Time.utc(2023, 1, 5)

    assert_equal 40, GumroadDailyAnalyticsCompiler.compile_gumroad_fee_cents(between: range)
  end

  test ".compile_gumroad_fee_cents aggregates service charges" do
    insert_service_charge!(created_at: Time.utc(2023, 1, 5), charge_cents: 10)
    insert_service_charge!(created_at: Time.utc(2023, 1, 5), charge_cents: 20)
    insert_service_charge!(created_at: Time.utc(2023, 1, 5), charge_cents: 30)

    range = Time.utc(2023, 1, 5)..Time.utc(2023, 1, 5)

    assert_equal 60, GumroadDailyAnalyticsCompiler.compile_gumroad_fee_cents(between: range)
  end

  test ".compile_gumroad_fee_cents ignores failed service charges" do
    insert_service_charge!(created_at: Time.utc(2023, 1, 5), charge_cents: 10)
    insert_service_charge!(created_at: Time.utc(2023, 1, 5), charge_cents: 20, state: "failed")
    insert_service_charge!(created_at: Time.utc(2023, 1, 5), charge_cents: 30)

    range = Time.utc(2023, 1, 5)..Time.utc(2023, 1, 5)

    assert_equal 40, GumroadDailyAnalyticsCompiler.compile_gumroad_fee_cents(between: range)
  end

  test ".compile_gumroad_fee_cents ignores refunded service charges" do
    insert_service_charge!(created_at: Time.utc(2023, 1, 5), charge_cents: 10)
    insert_service_charge!(created_at: Time.utc(2023, 1, 5), charge_cents: 20, charge_processor_refunded: true)
    insert_service_charge!(created_at: Time.utc(2023, 1, 5), charge_cents: 30)

    range = Time.utc(2023, 1, 5)..Time.utc(2023, 1, 5)

    assert_equal 40, GumroadDailyAnalyticsCompiler.compile_gumroad_fee_cents(between: range)
  end

  test ".compile_creators_with_sales aggregates data for the dates provided" do
    insert_purchase!(created_at: Time.utc(2023, 1, 4), product: links(:named_seller_product))
    insert_purchase!(created_at: Time.utc(2023, 1, 5), product: links(:named_seller_product))
    insert_purchase!(created_at: Time.utc(2023, 1, 6), product: links(:basic_user_product))
    insert_purchase!(created_at: Time.utc(2023, 1, 7), product: links(:another_seller_product))
    insert_purchase!(created_at: Time.utc(2023, 1, 8), product: links(:named_seller_product))

    range = Time.utc(2023, 1, 5)..Time.utc(2023, 1, 7)

    assert_equal 3, GumroadDailyAnalyticsCompiler.compile_creators_with_sales(between: range)
  end

  test ".compile_creators_with_sales aggregates creators with at least a one dollar sale" do
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 99, product: links(:named_seller_product))
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 100, product: links(:basic_user_product))
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 150, product: links(:another_seller_product))

    range = Time.utc(2023, 1, 5)..Time.utc(2023, 1, 5)

    assert_equal 2, GumroadDailyAnalyticsCompiler.compile_creators_with_sales(between: range)
  end

  test ".compile_creators_with_sales does not count the same creator twice" do
    product = links(:named_seller_product)
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 100, product:)
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 150, product:)

    range = Time.utc(2023, 1, 5)..Time.utc(2023, 1, 5)

    assert_equal 1, GumroadDailyAnalyticsCompiler.compile_creators_with_sales(between: range)
  end

  test ".compile_creators_with_sales ignores suspended creators" do
    users(:named_seller).update_columns(user_risk_state: "suspended_for_fraud")
    users(:another_seller).update_columns(user_risk_state: "suspended_for_tos_violation")
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 100, product: links(:named_seller_product))
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 100, product: links(:another_seller_product))

    range = Time.utc(2023, 1, 5)..Time.utc(2023, 1, 5)

    assert_equal 0, GumroadDailyAnalyticsCompiler.compile_creators_with_sales(between: range)
  end

  test ".compile_creators_with_sales ignores unsuccessful purchases" do
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 100, product: links(:named_seller_product))
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 200, purchase_state: "failed", product: links(:basic_user_product))
    insert_purchase!(
      created_at: Time.utc(2023, 1, 5),
      price_cents: 300,
      purchase_state: "in_progress",
      product: links(:another_seller_product)
    )

    range = Time.utc(2023, 1, 5)..Time.utc(2023, 1, 5)

    assert_equal 1, GumroadDailyAnalyticsCompiler.compile_creators_with_sales(between: range)
  end

  test ".compile_creators_with_sales ignores refunded purchases" do
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 100, product: links(:named_seller_product))
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 200, stripe_refunded: true, product: links(:basic_user_product))
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 300, product: links(:another_seller_product))

    range = Time.utc(2023, 1, 5)..Time.utc(2023, 1, 5)

    assert_equal 2, GumroadDailyAnalyticsCompiler.compile_creators_with_sales(between: range)
  end

  test ".compile_gumroad_discover_price_cents aggregates data for the dates provided" do
    insert_purchase!(created_at: Time.utc(2023, 1, 4), was_product_recommended: true)
    insert_purchase!(created_at: Time.utc(2023, 1, 5), was_product_recommended: true)
    insert_purchase!(created_at: Time.utc(2023, 1, 6), was_product_recommended: true)
    insert_purchase!(created_at: Time.utc(2023, 1, 7), was_product_recommended: true)
    insert_purchase!(created_at: Time.utc(2023, 1, 8), was_product_recommended: true)

    range = Time.utc(2023, 1, 5)..Time.utc(2023, 1, 7)

    assert_equal 300, GumroadDailyAnalyticsCompiler.compile_gumroad_discover_price_cents(between: range)
  end

  test ".compile_gumroad_discover_price_cents aggregates discovery purchase amounts" do
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 100, was_product_recommended: true)
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 200)
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 300, was_product_recommended: true)

    range = Time.utc(2023, 1, 5)..Time.utc(2023, 1, 5)

    assert_equal 400, GumroadDailyAnalyticsCompiler.compile_gumroad_discover_price_cents(between: range)
  end

  test ".compile_gumroad_discover_price_cents ignores unsuccessful purchases" do
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 100, was_product_recommended: true)
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 200, was_product_recommended: true, purchase_state: "failed")
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 300, was_product_recommended: true, purchase_state: "in_progress")

    range = Time.utc(2023, 1, 5)..Time.utc(2023, 1, 5)

    assert_equal 100, GumroadDailyAnalyticsCompiler.compile_gumroad_discover_price_cents(between: range)
  end

  test ".compile_gumroad_discover_price_cents ignores refunded purchases" do
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 100, was_product_recommended: true)
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 200, was_product_recommended: true, stripe_refunded: true)
    insert_purchase!(created_at: Time.utc(2023, 1, 5), price_cents: 300, was_product_recommended: true)

    range = Time.utc(2023, 1, 5)..Time.utc(2023, 1, 5)

    assert_equal 400, GumroadDailyAnalyticsCompiler.compile_gumroad_discover_price_cents(between: range)
  end

  private
    def insert_purchase!(
      created_at:,
      price_cents: 100,
      fee_cents: nil,
      purchase_state: "successful",
      stripe_refunded: nil,
      product: links(:named_seller_product),
      was_product_recommended: false
    )
      Purchase.insert!({
        seller_id: product.user_id,
        link_id: product.id,
        email: "analytics-compiler-#{SecureRandom.hex(8)}@example.com",
        price_cents:,
        fee_cents: fee_cents || price_cents / 10,
        total_transaction_cents: price_cents,
        displayed_price_cents: price_cents,
        displayed_price_currency_type: "usd",
        purchase_state:,
        stripe_refunded:,
        succeeded_at: created_at,
        flags: was_product_recommended ? DISCOVER_RECOMMENDED_FLAG : 0,
        created_at:,
        updated_at: created_at,
      })
    end

    def insert_service_charge!(created_at:, charge_cents:, state: "successful", charge_processor_refunded: false)
      ServiceCharge.insert!({
        user_id: users(:named_seller).id,
        charge_cents:,
        charge_cents_currency: "usd",
        state:,
        succeeded_at: created_at,
        charge_processor_refunded:,
        created_at:,
        updated_at: created_at,
      })
    end
end
