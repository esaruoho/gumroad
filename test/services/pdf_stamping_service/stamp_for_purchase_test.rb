# frozen_string_literal: true

require "test_helper"

class PdfStampingService::StampForPurchaseTest < ActiveSupport::TestCase
  # Sharpened skip-stub.
  # Original: spec/services/pdf_stamping_service/stamp_for_purchase_spec.rb
  # Blocker: PDF stamping pipeline (CombinePDF + S3-backed product_files); service downloads files from S3, stamps each page, re-uploads. Requires real MinIO/S3 plus a stamped PDF fixture corpus.
  test "TODO: migrate spec/services/pdf_stamping_service/stamp_for_purchase_spec.rb" do
    skip "Fixture-hostile — see top-of-file blocker note"
  end
end
