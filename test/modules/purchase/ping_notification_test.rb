# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during mig-b sweep.
# Spec is :vcr-tagged. 26 FactoryBot refs across purchases with per-test
# mutated state (chargeback_date, stripe_refunded, dispute_won, custom fields).
# Net-new fixture tables required: purchase_custom_fields, refunds, license
# relations, resource_subscriptions — over the 5-table threshold. Each test
# asserts on a large per-mutation payload key set.
#
# Original spec: spec/modules/purchase/ping_notification_spec.rb
class Purchase::PingNotificationTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — multi-table + per-test state mutation, requires manual rewrite" do
    skip "TODO: migrate spec/modules/purchase/ping_notification_spec.rb (26 FB refs, 5+ net-new tables, VCR)"
  end
end
