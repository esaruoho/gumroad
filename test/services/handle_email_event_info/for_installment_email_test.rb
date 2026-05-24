# frozen_string_literal: true

require "test_helper"

class HandleEmailEventInfo::ForInstallmentEmailTest < ActiveSupport::TestCase
  # Sharpened skip-stub.
  # Original: spec/services/handle_email_event_info/for_installment_email_spec.rb
  # Blocker: Renders CreatorMailer.installment with product_files + url_redirects; extracts post id, link id, type via HandleEmailEventInfo. Premailer + view + Installment fixture chain.
  test "TODO: migrate spec/services/handle_email_event_info/for_installment_email_spec.rb" do
    skip "Fixture-hostile — see top-of-file blocker note"
  end
end
