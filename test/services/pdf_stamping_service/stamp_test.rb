# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration.
# Original: spec/services/pdf_stamping_service/stamp_spec.rb
# Reason: depends on real S3-hosted PDF assets (specs/*.pdf via AWS_S3_ENDPOINT) and
# the pdftk binary — binary-asset trap per skill skip-batch-authorization.
class PdfStampingService::StampTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — PDF/binary asset trap" do
    skip "TODO: migrate spec/services/pdf_stamping_service/stamp_spec.rb (S3 PDF assets + pdftk binary)"
  end
end
