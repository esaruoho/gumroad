require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration —
# receipt-presenter sub-specs sit on the recurring/subscription deep web
# (membership_product + membership_purchase + Charge + Subscription + Gift),
# which is documented skip-batch territory in the migration directive even
# at modest FB-ref counts. Revisit post-deadline with a manual fixtures rewrite.
#
# Original spec: spec/presenters/receipt_presenter/mail_subject_spec.rb (12 FB refs)
class ReceiptPresenter::MailSubjectTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — subscription/charge deep-web, requires manual rewrite" do
    skip "TODO: migrate spec/presenters/receipt_presenter/mail_subject_spec.rb (12 FB refs, subscription deep web)"
  end
end
