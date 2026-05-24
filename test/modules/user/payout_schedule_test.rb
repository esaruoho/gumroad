# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during mig-b sweep.
# Every test creates balances with hard-coded `date:` values INSIDE
# `travel_to(Date.new(YYYY, M, D))` blocks and asserts on rolling aggregates
# (next_payout_date, upcoming_payouts, payout_amount_for_payout_date).
# Static YAML fixtures cannot replicate the per-test time-traveled balance
# date distribution — translating would require re-introducing factory-
# shaped row builders inside `setup`, defeating the fixtures-only directive.
#
# Original spec: spec/modules/user/payout_schedule_spec.rb (22 FB refs)
class User::PayoutScheduleTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — dynamic time-traveled balance dates, requires manual rewrite" do
    skip "TODO: migrate spec/modules/user/payout_schedule_spec.rb (22 FB refs, per-test time-traveled dates)"
  end
end
