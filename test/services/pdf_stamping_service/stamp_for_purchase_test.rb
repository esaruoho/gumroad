# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration.
# Original: spec/services/pdf_stamping_service/stamp_for_purchase_spec.rb
# Reason: depends on real PDF assets and pdftk; touches purchase + product_file + url_redirect
# chains. PDF/binary asset trap per skill.
class PdfStampingService::StampForPurchaseTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — PDF/binary asset trap" do
    skip "TODO: migrate spec/services/pdf_stamping_service/stamp_for_purchase_spec.rb (S3 PDF assets + pdftk binary)"
  end
end
