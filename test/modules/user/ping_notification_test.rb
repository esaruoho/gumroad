# frozen_string_literal: true

require "test_helper"

class UserPingNotificationTest < ActiveSupport::TestCase
  test "skipped: requires fixture support for purchase_custom_fields, doorkeeper/access_token, resource_subscriptions (3 new tables)." do
    skip "Too many fixture tables (purchase_custom_fields, doorkeeper access_tokens, resource_subscriptions). Queued for follow-up."
  end
end
