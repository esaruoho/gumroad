# frozen_string_literal: true

require "test_helper"

class CreatorAnalytics::CachingProxy::Formatters::ByReferralTest < ActiveSupport::TestCase
  setup do
    @user = users(:basic_user)
    @dates = (Date.new(2021, 1, 1)..Date.new(2021, 1, 5)).to_a
    insert_first_sale_for_analytics!
    @service = CreatorAnalytics::CachingProxy.new(@user)
  end

  test "#merge_data_by_referral returns data merged by referral" do
    day_one = {
      by_referral: {
        views: {
          "tPsrl" => { "direct" => [1], "Twitter" => [1], "Facebook" => [1] },
          "EpUED" => { "direct" => [1], "Twitter" => [1], "Facebook" => [1] }
        },
        sales: {
          "tPsrl" => { "direct" => [1], "Twitter" => [1], "Facebook" => [1] },
          "EpUED" => { "direct" => [1], "Twitter" => [1], "Facebook" => [1] }
        },
        totals: {
          "tPsrl" => { "direct" => [1], "Twitter" => [1], "Facebook" => [1] },
          "EpUED" => { "direct" => [1], "Twitter" => [1], "Facebook" => [1] }
        }
      },
      dates_and_months: [
        { date: "Friday, January 1st", month: "January 2021", month_index: 0 },
      ]
    }
    day_two_and_three = {
      by_referral: {
        views: {
          "tPsrl" => { "direct" => [1, 1], "Twitter" => [1, 1] },
          "EpUED" => { "direct" => [1, 1], "Twitter" => [1, 1] },
          "Mmwrc" => { "direct" => [1, 1], "Twitter" => [1, 1] }
        },
        sales: {
          "tPsrl" => { "direct" => [1, 1], "Twitter" => [1, 1] },
          "EpUED" => { "direct" => [1, 1], "Twitter" => [1, 1] },
          "Mmwrc" => { "direct" => [1, 1], "Twitter" => [1, 1] }
        },
        totals: {
          "tPsrl" => { "direct" => [1, 1], "Twitter" => [1, 1] },
          "EpUED" => { "direct" => [1, 1], "Twitter" => [1, 1] },
          "Mmwrc" => { "direct" => [1, 1], "Twitter" => [1, 1] }
        }
      },
      dates_and_months: [
        { date: "Saturday, January 2nd", month: "January 2021", month_index: 0 },
        { date: "Sunday, January 3rd", month: "January 2021", month_index: 0 },
      ]
    }
    day_four_and_five = {
      by_referral: {
        views: {
          "tPsrl" => { "direct" => [1, 1], "Twitter" => [1, 1] },
          "EpUED" => { "direct" => [1, 1], "Twitter" => [1, 1] },
          "Mmwrc" => { "direct" => [1, 1], "Twitter" => [1, 1] }
        },
        sales: {
          "tPsrl" => { "direct" => [1, 1], "Twitter" => [1, 1] },
          "EpUED" => { "direct" => [1, 1], "Twitter" => [1, 1] },
          "Mmwrc" => { "direct" => [1, 1], "Twitter" => [1, 1] }
        },
        totals: {
          "tPsrl" => { "direct" => [1, 1], "Twitter" => [1, 1] },
          "EpUED" => { "direct" => [1, 1], "Twitter" => [1, 1] },
          "Mmwrc" => { "direct" => [1, 1], "Twitter" => [1, 1] }
        }
      },
      dates_and_months: [
        { date: "Monday, January 4th", month: "January 2021", month_index: 0 },
        { date: "Tuesday, January 5th", month: "January 2021", month_index: 0 },
      ]
    }
    expected = {
      by_referral: {
        views: {
          "tPsrl" => { "direct" => [1, 1, 1, 1, 1], "Twitter" => [1, 1, 1, 1, 1], "Facebook" => [1, 0, 0, 0, 0] },
          "EpUED" => { "direct" => [1, 1, 1, 1, 1], "Twitter" => [1, 1, 1, 1, 1], "Facebook" => [1, 0, 0, 0, 0] },
          "Mmwrc" => { "direct" => [0, 1, 1, 1, 1], "Twitter" => [0, 1, 1, 1, 1] }
        },
        sales: {
          "tPsrl" => { "direct" => [1, 1, 1, 1, 1], "Twitter" => [1, 1, 1, 1, 1], "Facebook" => [1, 0, 0, 0, 0] },
          "EpUED" => { "direct" => [1, 1, 1, 1, 1], "Twitter" => [1, 1, 1, 1, 1], "Facebook" => [1, 0, 0, 0, 0] },
          "Mmwrc" => { "direct" => [0, 1, 1, 1, 1], "Twitter" => [0, 1, 1, 1, 1] }
        },
        totals: {
          "tPsrl" => { "direct" => [1, 1, 1, 1, 1], "Twitter" => [1, 1, 1, 1, 1], "Facebook" => [1, 0, 0, 0, 0] },
          "EpUED" => { "direct" => [1, 1, 1, 1, 1], "Twitter" => [1, 1, 1, 1, 1], "Facebook" => [1, 0, 0, 0, 0] },
          "Mmwrc" => { "direct" => [0, 1, 1, 1, 1], "Twitter" => [0, 1, 1, 1, 1] }
        }
      },
      dates_and_months: [
        { date: "Friday, January 1st", month: "January 2021", month_index: 0 },
        { date: "Saturday, January 2nd", month: "January 2021", month_index: 0 },
        { date: "Sunday, January 3rd", month: "January 2021", month_index: 0 },
        { date: "Monday, January 4th", month: "January 2021", month_index: 0 },
        { date: "Tuesday, January 5th", month: "January 2021", month_index: 0 },
      ],
      start_date: "Jan  1, 2021",
      end_date: "Jan  5, 2021",
      first_sale_date: "Aug 14, 2020"
    }

    result = @service.merge_data_by_referral([day_one, day_two_and_three, day_four_and_five], @dates)

    assert_equal expected.deep_stringify_keys, result.deep_stringify_keys
  end

  test "#group_referral_data_by_day reformats the data by day" do
    data = {
      dates_and_months: [
        { date: "Friday, January 1st", month: "January 2021", month_index: 0 },
        { date: "Saturday, January 2nd", month: "January 2021", month_index: 0 }
      ],
      start_date: "Jan  1, 2021",
      end_date: "Jan  7, 2021",
      by_referral: {
        views: {
          "tPsrl" => { "direct" => [1, 1], "Twitter" => [1, 1] },
          "EpUED" => { "Google" => [1, 1], "Facebook" => [1, 1] }
        },
        sales: {
          "tPsrl" => { "direct" => [1, 1], "Tiktok" => [1, 1] },
          "EpUED" => {}
        },
        totals: {
          "tPsrl" => { "direct" => [1, 1], "Tiktok" => [1, 1] },
          "EpUED" => {}
        }
      },
      first_sale_date: "Aug 14, 2020"
    }
    expected_with_years = {
      dates: [
        "Friday, January 1st 2021",
        "Saturday, January 2nd 2021"
      ],
      by_referral: data[:by_referral]
    }
    expected_without_years = expected_with_years.merge(
      dates: [
        "Friday, January 1st",
        "Saturday, January 2nd"
      ]
    )

    assert_equal expected_with_years.deep_stringify_keys,
                 @service.group_referral_data_by_day(data).deep_stringify_keys
    assert_equal expected_without_years.deep_stringify_keys,
                 @service.group_referral_data_by_day(data, days_without_years: true).deep_stringify_keys
  end

  test "#group_referral_data_by_month reformats the data by month" do
    data = {
      dates_and_months: [
        { date: "Saturday, July 31st", month: "July 2021", month_index: 0 },
        { date: "Sunday, August 1st", month: "August 2021", month_index: 1 },
        { date: "Monday, August 2nd", month: "August 2021", month_index: 1 }
      ],
      start_date: "July 31, 2021",
      end_date: "August 2, 2021",
      by_referral: {
        views: {
          "EpUED" => { "Google" => [1, 1, 1], "Facebook" => [1, 1, 1] },
        },
        sales: {
          "tPsrl" => { "direct" => [1, 1, 1], "Tiktok" => [1, 1, 1] },
        },
        totals: {
          "tPsrl" => { "direct" => [1, 1, 1], "Tiktok" => [1, 1, 1] },
        }
      },
      first_sale_date: "Aug 14, 2020"
    }
    expected = {
      dates: [
        "July 2021",
        "August 2021"
      ],
      by_referral: {
        views: {
          "EpUED" => { "Google" => [1, 2], "Facebook" => [1, 2] }
        },
        sales: {
          "tPsrl" => { "direct" => [1, 2], "Tiktok" => [1, 2] }
        },
        totals: {
          "tPsrl" => { "direct" => [1, 2], "Tiktok" => [1, 2] }
        }
      }
    }

    assert_equal expected.deep_stringify_keys, @service.group_referral_data_by_month(data).deep_stringify_keys
  end

  private
    def insert_first_sale_for_analytics!
      product = links(:basic_user_product)
      Purchase.insert!({
        seller_id: @user.id,
        link_id: product.id,
        email: "by-referral-buyer@example.com",
        price_cents: 100,
        total_transaction_cents: 100,
        displayed_price_cents: 100,
        displayed_price_currency_type: "usd",
        purchase_state: "successful",
        succeeded_at: Date.new(2020, 8, 15),
        created_at: Date.new(2020, 8, 15),
        updated_at: Date.new(2020, 8, 15),
      })
    end
end
