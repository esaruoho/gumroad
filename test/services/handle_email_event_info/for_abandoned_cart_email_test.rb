# frozen_string_literal: true

require "test_helper"

class HandleEmailEventInfo::ForAbandonedCartEmailTest < ActiveSupport::TestCase
  # Sharpened skip-stub.
  # Original: spec/services/handle_email_event_info/for_abandoned_cart_email_spec.rb
  # Blocker: AbandonedCartWorker + Cart + Charge + EmailEvent + URL redirect chain through ContactingCreatorMailer pipeline. Renders mail body for HandleEmailEventInfo extraction.
  test "TODO: migrate spec/services/handle_email_event_info/for_abandoned_cart_email_spec.rb" do
    skip "Fixture-hostile — see top-of-file blocker note"
  end
end
