# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during mig-b sweep.
# Requires membership-shaped product fixtures (recurrence + price row),
# subscriptions, membership_purchases, plus licenses and purchase_custom_fields.
# Each test mutates per-test subscription state (cancelled_by_buyer/admin/seller,
# failed_at, ended_at, deactivated_at, user_requested_cancellation_at) and
# asserts on payload key sets keyed on that mutated state.
#
# Net-new fixture tables: licenses, purchase_custom_fields, plus membership-
# variant of products — over the 5-table threshold and the per-test state-
# mutation shape can't be expressed as static YAML.
#
# Original spec: spec/modules/subscription/ping_notification_spec.rb (22 FB refs)
class Subscription::PingNotificationTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — multi-table + per-test state mutation, requires manual rewrite" do
    skip "TODO: migrate spec/modules/subscription/ping_notification_spec.rb (22 FB refs, 5+ net-new tables)"
  end
end
