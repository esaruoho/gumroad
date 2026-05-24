# frozen_string_literal: true

require "test_helper"

class BlackRecurringServiceTest < ActiveSupport::TestCase
  test "mark_active! transitions to active" do
    service = BlackRecurringService.create!(
      user: users(:named_seller),
      state: "inactive",
      price_cents: 10_00,
      recurrence: :monthly
    )
    service.mark_active!
    assert_equal "active", service.reload.state
  end
end
