# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during mig-b sweep.
# 42 FactoryBot refs (>40 threshold). Every test creates many purchases inside
# `travel_to(N.days.ago)` blocks at different price_cents and computes rolling-
# year averages and projected annual transaction volume. Static YAML fixtures
# can't replicate the per-test time-distribution shape that the rolling-year
# aggregates depend on.
#
# Original spec: spec/modules/user/payment_stats_spec.rb
class User::PaymentStatsTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — >40 FB refs, time-traveled per-test purchases, requires manual rewrite" do
    skip "TODO: migrate spec/modules/user/payment_stats_spec.rb (42 FB refs, rolling-year time-traveled aggregates)"
  end
end
