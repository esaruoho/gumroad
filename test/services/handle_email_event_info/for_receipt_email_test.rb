# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during bulk fixtures-only migration:
# 456 LoC RSpec with shared_examples × provider (SendGrid/Resend) contexts and
# 16 FactoryBot refs (purchase/receipt/email-event chains). Revisit individually.
#
# Original spec: spec/services/handle_email_event_info/for_receipt_email_spec.rb
class HandleEmailEventInfo::ForReceiptEmailTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — shared_examples-heavy, fixture-hostile" do
    skip "TODO: migrate spec/services/handle_email_event_info/for_receipt_email_spec.rb"
  end
end
