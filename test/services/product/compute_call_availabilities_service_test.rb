# frozen_string_literal: true

require "test_helper"

class Product::ComputeCallAvailabilitiesServiceTest < ActiveSupport::TestCase
  setup do
    @call_product = links(:named_seller_call_product)
    @call_product.user.update_columns(timezone: "UTC")
    Call.where(purchase_id: @call_product.sales.select(:id)).delete_all
    CallAvailability.where(call: @call_product).delete_all
    @call_product.call_limitation_info&.delete
    @call_limitation_info = @call_product.create_call_limitation_info!(minimum_notice_in_minutes: 0)
    @call_product.reload
    travel_to Time.utc(2015, 4, 1)
  end

  teardown do
    travel_back
  end

  test "#perform returns an empty array when product is not a call product" do
    assert_equal [], Product::ComputeCallAvailabilitiesService.new(links(:basic_user_product)).perform
  end

  test "#perform excludes availabilities from the past" do
    @call_limitation_info.update!(minimum_notice_in_minutes: 0)

    create_call_availability(start_time: 10.hours.ago, end_time: 1.hour.from_now)
    create_call_availability(start_time: 1.hour.from_now, end_time: 2.hours.from_now)

    assert_equal(
      [{ start_time: Time.current, end_time: 2.hours.from_now }],
      service.perform
    )
  end

  test "#perform excludes availabilities within the minimum notice period" do
    @call_limitation_info.update!(minimum_notice_in_minutes: 1.hour.in_minutes)

    create_call_availability(start_time: 10.hours.ago, end_time: 2.hours.from_now)

    assert_equal(
      [{ start_time: 1.hour.from_now, end_time: 2.hours.from_now }],
      service.perform
    )
  end

  test "#perform excludes days that exceed the seller timezone call limit" do
    seller_timezone = Time.find_zone("Pacific Time (US & Canada)")
    buyer_timezone = Time.find_zone("Eastern Time (US & Canada)")
    system_timezone = Time.find_zone("UTC")

    @call_product.user.update_columns(timezone: seller_timezone.name)
    @call_limitation_info.update!(maximum_calls_per_day: 1, minimum_notice_in_minutes: 0)

    travel_to seller_timezone.local(2015, 4, 1, 12)

    available_from_apr_1_to_apr_6 = create_call_availability(
      start_time: seller_timezone.local(2015, 4, 1, 12),
      end_time: seller_timezone.local(2015, 4, 6, 12)
    )
    create_sold_call(
      start_time: seller_timezone.local(2015, 4, 2, 12).in_time_zone(buyer_timezone),
      end_time: seller_timezone.local(2015, 4, 2, 13).in_time_zone(buyer_timezone)
    )
    create_sold_call(
      start_time: seller_timezone.local(2015, 4, 3, 12).in_time_zone(buyer_timezone),
      end_time: seller_timezone.local(2015, 4, 3, 13).in_time_zone(buyer_timezone)
    )
    sold_apr_5_to_apr_6 = create_sold_call(
      start_time: seller_timezone.local(2015, 4, 5, 12).in_time_zone(buyer_timezone),
      end_time: seller_timezone.local(2015, 4, 6, 1).in_time_zone(buyer_timezone)
    )

    availabilities = Time.use_zone(system_timezone) { service.perform }

    assert_equal(
      [
        {
          start_time: available_from_apr_1_to_apr_6.start_time,
          end_time: seller_timezone.local(2015, 4, 1).end_of_day,
        },
        {
          start_time: seller_timezone.local(2015, 4, 4).beginning_of_day,
          end_time: seller_timezone.local(2015, 4, 4).end_of_day,
        },
        {
          start_time: sold_apr_5_to_apr_6.end_time,
          end_time: available_from_apr_1_to_apr_6.end_time,
        },
      ],
      availabilities
    )
  end

  test "#perform excludes sold availabilities" do
    create_call_availability(start_time: 10.hours.from_now, end_time: 16.hours.from_now)
    create_call_availability(start_time: 10.hours.from_now, end_time: 16.hours.from_now)

    create_sold_call(start_time: 9.hours.from_now, end_time: 11.hours.from_now)
    create_sold_call(start_time: 14.hours.from_now, end_time: 15.hours.from_now)

    assert_equal(
      [
        { start_time: 11.hours.from_now, end_time: 14.hours.from_now },
        { start_time: 15.hours.from_now, end_time: 16.hours.from_now },
      ],
      service.perform
    )
  end

  test "#perform includes sold availabilities that no longer occupy availability" do
    create_call_availability(start_time: 10.hours.from_now, end_time: 16.hours.from_now)

    create_sold_call(start_time: 10.hours.from_now, end_time: 11.hours.from_now, refunded: true)
    create_sold_call(start_time: 11.hours.from_now, end_time: 12.hours.from_now, purchase_state: "failed")

    assert_equal(
      [{ start_time: 10.hours.from_now, end_time: 16.hours.from_now }],
      service.perform
    )
  end

  private
    def service
      Product::ComputeCallAvailabilitiesService.new(@call_product)
    end

    def create_call_availability(start_time:, end_time:)
      CallAvailability.create!(call: @call_product, start_time:, end_time:)
    end

    def create_sold_call(start_time:, end_time:, purchase_state: "successful", refunded: false)
      purchase = Purchase.new(
        seller: @call_product.user,
        link: @call_product,
        email: "call-buyer-#{SecureRandom.hex(4)}@example.com",
        price_cents: 100,
        total_transaction_cents: 100,
        displayed_price_cents: 100,
        displayed_price_currency_type: "usd",
        purchase_state:,
        succeeded_at: Time.current,
        stripe_refunded: refunded,
        fee_cents: 0,
      )
      Purchase.skip_callback(:create, :before, :price_not_too_low)
      begin
        purchase.save!(validate: false)
      ensure
        Purchase.set_callback(:create, :before, :price_not_too_low)
      end
      call = Call.new(purchase:, start_time:, end_time:)
      call.save(validate: false)
      call
    end
end
