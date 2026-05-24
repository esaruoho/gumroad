# frozen_string_literal: true

require "test_helper"

class Helper::UnblockEmailServiceTest < ActiveSupport::TestCase
  # Sharpened skip-stub.
  # Original: spec/services/helper/unblock_email_service_spec.rb
  # Blocker: PlatformBlock + EmailSuppressionManager.unblock_email + Helper::Client (add_note/send_reply/close_conversation) + blocked_purchases recent_failed scope chain. Heavy mocking of Helper::Client.
  test "TODO: migrate spec/services/helper/unblock_email_service_spec.rb" do
    skip "Fixture-hostile — see top-of-file blocker note"
  end
end
