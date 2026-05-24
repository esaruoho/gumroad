# frozen_string_literal: true

require "test_helper"

class CreatorAnalytics::WebTest < ActiveSupport::TestCase
  FakeViews = Struct.new(:by_product_and_date, :by_product_and_country_and_state, :by_product_and_referrer_and_date, keyword_init: true)
  FakeSales = Struct.new(:by_product_and_date, :by_product_and_country_and_state, :by_product_and_referrer_and_date, keyword_init: true)

  setup do
    @user = users(:analytics_seller)
    @user.update_columns(timezone: "UTC")
    purchases(:analytics_deleted_with_sales_purchase).update_columns(
      created_at: Time.utc(2021, 1, 1),
      succeeded_at: Time.utc(2021, 1, 1)
    )
    @products = @user.products_for_creator_analytics.to_a
    @product_one = @products[0]
    @product_two = @products[1]
    @service = CreatorAnalytics::Web.new(
      user: @user,
      dates: (Date.new(2021, 1, 1)..Date.new(2021, 1, 3)).to_a
    )
  end

  test "#by_date returns expected data" do
    with_analytics_sources do
      assert_equal(
        {
          dates_and_months: [
            { date: "Friday, January 1st", month: "January 2021", month_index: 0 },
            { date: "Saturday, January 2nd", month: "January 2021", month_index: 0 },
            { date: "Sunday, January 3rd", month: "January 2021", month_index: 0 },
          ],
          start_date: "Jan  1, 2021",
          end_date: "Jan  3, 2021",
          first_sale_date: "Jan  1, 2021",
          by_date: {
            views: { @product_one.unique_permalink => [1, 0, 3], @product_two.unique_permalink => [0, 0, 1] },
            sales: { @product_one.unique_permalink => [1, 0, 2], @product_two.unique_permalink => [0, 0, 1] },
            totals: { @product_one.unique_permalink => [100, 0, 200], @product_two.unique_permalink => [0, 0, 100] },
          },
        },
        @service.by_date
      )
    end
  end

  test "#by_state returns expected data" do
    us_ny = state_counts("NY" => 1)

    with_analytics_sources do
      assert_equal(
        {
          by_state: {
            views: {
              @product_one.unique_permalink => {
                "United States" => us_ny,
                nil => 1,
                "France" => 2,
              },
              @product_two.unique_permalink => {
                "United States" => us_ny,
              },
            },
            sales: {
              @product_one.unique_permalink => {
                "United States" => us_ny,
                nil => 1,
                "France" => 1,
              },
              @product_two.unique_permalink => {
                "United States" => us_ny,
              },
            },
            totals: {
              @product_one.unique_permalink => {
                "United States" => state_counts("NY" => 100),
                nil => 100,
                "France" => 100,
              },
              @product_two.unique_permalink => {
                "United States" => state_counts("NY" => 100),
              },
            },
          },
        },
        @service.by_state
      )
    end
  end

  test "#by_referral returns expected data" do
    with_analytics_sources do
      assert_equal(
        {
          dates_and_months: [
            { date: "Friday, January 1st", month: "January 2021", month_index: 0 },
            { date: "Saturday, January 2nd", month: "January 2021", month_index: 0 },
            { date: "Sunday, January 3rd", month: "January 2021", month_index: 0 },
          ],
          start_date: "Jan  1, 2021",
          end_date: "Jan  3, 2021",
          first_sale_date: "Jan  1, 2021",
          by_referral: {
            views: {
              @product_one.unique_permalink => {
                "Google" => [0, 0, 2],
                "direct" => [1, 0, 1],
              },
              @product_two.unique_permalink => {
                "Google" => [0, 0, 1],
              },
            },
            sales: {
              @product_one.unique_permalink => {
                "Google" => [0, 0, 1],
                "direct" => [1, 0, 1],
              },
              @product_two.unique_permalink => {
                "Google" => [0, 0, 1],
              },
            },
            totals: {
              @product_one.unique_permalink => {
                "Google" => [0, 0, 100],
                "direct" => [100, 0, 100],
              },
              @product_two.unique_permalink => {
                "Google" => [0, 0, 100],
              },
            },
          },
        },
        @service.by_referral
      )
    end
  end

  test "#by_referral keeps filters aligned with histogram buckets when midnight is skipped" do
    user = users(:basic_user)
    user.update_columns(timezone: "Tehran")
    product = links(:basic_user_product)
    service = CreatorAnalytics::Web.new(user:, dates: [Date.new(2026, 3, 22)])

    views = FakeViews.new(
      by_product_and_referrer_and_date: { [product.id, "google.com", "2026-03-22"] => 1 },
      by_product_and_date: {},
      by_product_and_country_and_state: {}
    )
    sales = FakeSales.new(
      by_product_and_referrer_and_date: { [product.id, "google.com", "2026-03-22"] => { count: 1, total: 0 } },
      by_product_and_date: {},
      by_product_and_country_and_state: {}
    )

    with_analytics_sources(views:, sales:) do
      result = service.by_referral

      assert_equal(
        {
          views: { product.unique_permalink => { "Google" => [1] } },
          sales: { product.unique_permalink => { "Google" => [1] } },
          totals: { product.unique_permalink => { "Google" => [0] } },
        },
        result[:by_referral]
      )
    end
  end

  private
    def with_analytics_sources(views: default_views, sales: default_sales)
      CreatorAnalytics::ProductPageViews.stub(:new, views) do
        CreatorAnalytics::Sales.stub(:new, sales) do
          yield
        end
      end
    end

    def default_views
      FakeViews.new(
        by_product_and_date: {
          [@product_one.id, "2021-01-01"] => 1,
          [@product_one.id, "2021-01-03"] => 3,
          [@product_two.id, "2021-01-03"] => 1,
        },
        by_product_and_country_and_state: {
          [@product_one.id, nil, nil] => 1,
          [@product_one.id, "France", nil] => 2,
          [@product_one.id, "United States", "NY"] => 1,
          [@product_two.id, "United States", "NY"] => 1,
        },
        by_product_and_referrer_and_date: {
          [@product_one.id, nil, "2021-01-01"] => 1,
          [@product_one.id, nil, "2021-01-03"] => 1,
          [@product_one.id, "google.com", "2021-01-03"] => 2,
          [@product_two.id, "google.com", "2021-01-03"] => 1,
        }
      )
    end

    def default_sales
      FakeSales.new(
        by_product_and_date: {
          [@product_one.id, "2021-01-01"] => { count: 1, total: 100 },
          [@product_one.id, "2021-01-03"] => { count: 2, total: 200 },
          [@product_two.id, "2021-01-03"] => { count: 1, total: 100 },
        },
        by_product_and_country_and_state: {
          [@product_one.id, nil, nil] => { count: 1, total: 100 },
          [@product_one.id, "France", nil] => { count: 1, total: 100 },
          [@product_one.id, "United States", "NY"] => { count: 1, total: 100 },
          [@product_two.id, "United States", "NY"] => { count: 1, total: 100 },
        },
        by_product_and_referrer_and_date: {
          [@product_one.id, nil, "2021-01-01"] => { count: 1, total: 100 },
          [@product_one.id, nil, "2021-01-03"] => { count: 1, total: 100 },
          [@product_one.id, "google.com", "2021-01-03"] => { count: 1, total: 100 },
          [@product_two.id, "google.com", "2021-01-03"] => { count: 1, total: 100 },
        }
      )
    end

    def state_counts(counts)
      Array.new(STATES_SUPPORTED_BY_ANALYTICS.size, 0).tap do |values|
        counts.each do |state, count|
          values[STATES_SUPPORTED_BY_ANALYTICS.index(state)] = count
        end
      end
    end
end
