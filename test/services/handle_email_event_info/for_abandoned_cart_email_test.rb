# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during bulk fixtures-only migration:
# uses 5-deep RSpec `shared_examples` × provider (SendGrid/Resend) contexts that
# don't translate mechanically. Requires AbandonedCartWorkflow + Installment
# fixture chain plus MailerInfo.encrypt header construction. Revisit individually.
#
# Original spec: spec/services/handle_email_event_info/for_abandoned_cart_email_spec.rb
class HandleEmailEventInfo::ForAbandonedCartEmailTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — shared_examples-heavy, fixture-hostile" do
    skip "TODO: migrate spec/services/handle_email_event_info/for_abandoned_cart_email_spec.rb"
  end
end
