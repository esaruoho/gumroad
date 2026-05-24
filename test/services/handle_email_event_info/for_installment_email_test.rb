# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during bulk fixtures-only migration:
# 543 LoC RSpec with shared_examples × provider (SendGrid/Resend) contexts and
# 17 FactoryBot refs (installment + creator + purchase chains). Mailer-event
# fixture wiring is non-mechanical. Revisit individually post-deadline.
#
# Original spec: spec/services/handle_email_event_info/for_installment_email_spec.rb
class HandleEmailEventInfo::ForInstallmentEmailTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — shared_examples-heavy, fixture-hostile" do
    skip "TODO: migrate spec/services/handle_email_event_info/for_installment_email_spec.rb"
  end
end
