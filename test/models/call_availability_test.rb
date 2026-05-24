# frozen_string_literal: true

require "test_helper"

class CallAvailabilityTest < ActiveSupport::TestCase
  setup do
    seller = users(:another_seller)
    @call_product = Link.new(user: seller, name: "Call Product", filegroup: "url", native_type: "call", price_cents: 100)
    @call_product.save(validate: false)
  end

  def build_availability(**attrs)
    CallAvailability.new({ call: @call_product, start_time: 1.day.ago, end_time: 1.year.from_now }.merge(attrs))
  end

  test "drops sub-minute precision from start_time and end_time when assigning" do
    avail = build_availability(
      start_time: DateTime.parse("May 1 2024 10:28:01.123456 UTC"),
      end_time: DateTime.parse("May 1 2024 11:29:59.923456 UTC")
    )

    assert_equal DateTime.parse("May 1 2024 10:28:00 UTC"), avail.start_time
    assert_equal DateTime.parse("May 1 2024 11:29:00 UTC"), avail.end_time
  end

  test "drops sub-minute precision from start_time and end_time when querying" do
    avail = build_availability(
      start_time: DateTime.parse("May 1 2024 10:28:01.123456 UTC"),
      end_time: DateTime.parse("May 1 2024 11:29:59.923456 UTC")
    )
    avail.save!

    assert_equal avail, CallAvailability.find_by(start_time: avail.start_time.change(sec: 2))
    assert_equal avail, CallAvailability.find_by(end_time: avail.end_time.change(sec: 58))
  end

  test "validations: end time before start time adds an error" do
    avail = build_availability
    avail.end_time = avail.start_time - 1.hour
    refute avail.valid?
    assert_equal ["Start time must be before end time."], avail.errors.full_messages
  end

  test ".upcoming returns call availabilities that haven't ended" do
    freeze_time do
      not_started = CallAvailability.create!(call: @call_product, start_time: 1.day.from_now, end_time: 2.days.from_now)
      started_but_not_ended = CallAvailability.create!(call: @call_product, start_time: 2.days.ago, end_time: 2.days.from_now)
      _ended = CallAvailability.create!(call: @call_product, start_time: 2.days.ago, end_time: 1.day.ago)

      assert_equal [started_but_not_ended, not_started].sort_by(&:id), CallAvailability.upcoming.to_a.sort_by(&:id)
    end
  end

  test ".ordered_chronologically orders by start time and end time" do
    freeze_time do
      not_started = CallAvailability.create!(call: @call_product, start_time: 1.day.from_now, end_time: 2.days.from_now)
      started_but_not_ended = CallAvailability.create!(call: @call_product, start_time: 2.days.ago, end_time: 2.days.from_now)
      ended = CallAvailability.create!(call: @call_product, start_time: 2.days.ago, end_time: 1.day.ago)

      assert_equal [ended.id, started_but_not_ended.id, not_started.id], CallAvailability.ordered_chronologically.pluck(:id)
    end
  end

  test ".containing returns call availabilities that strictly contain the given time range" do
    freeze_time do
      not_started = CallAvailability.create!(call: @call_product, start_time: 1.day.from_now, end_time: 2.days.from_now)
      started_but_not_ended = CallAvailability.create!(call: @call_product, start_time: 2.days.ago, end_time: 2.days.from_now)
      _ended = CallAvailability.create!(call: @call_product, start_time: 2.days.ago, end_time: 1.day.ago)

      assert_equal [not_started, started_but_not_ended].sort_by(&:id),
                   CallAvailability.containing(not_started.start_time, not_started.end_time).to_a.sort_by(&:id)
      assert_equal [started_but_not_ended],
                   CallAvailability.containing(not_started.start_time - 1.second, not_started.end_time).to_a
      assert_empty CallAvailability.containing(not_started.start_time, not_started.end_time + 1.second).to_a
    end
  end
end
