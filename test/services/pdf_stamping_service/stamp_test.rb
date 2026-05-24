# frozen_string_literal: true

require "test_helper"

class PdfStampingService::StampTest < ActiveSupport::TestCase
  # Sharpened skip-stub.
  # Original: spec/services/pdf_stamping_service/stamp_spec.rb
  # Blocker: Same as stamp_for_purchase: CombinePDF + S3 download/upload. Tests stamp positioning + content extraction against real PDFs.
  test "TODO: migrate spec/services/pdf_stamping_service/stamp_spec.rb" do
    skip "Fixture-hostile — see top-of-file blocker note"
  end
end
