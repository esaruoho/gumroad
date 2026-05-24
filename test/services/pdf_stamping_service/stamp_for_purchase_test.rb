# frozen_string_literal: true

require "test_helper"

class PdfStampingService::StampForPurchaseTest < ActiveSupport::TestCase
  test "exposes a module-level perform! method via `extend self`" do
    assert PdfStampingService::StampForPurchase.respond_to?(:perform!)
    # Module methods can also be invoked through the singleton method list.
    assert_includes PdfStampingService::StampForPurchase.singleton_class.instance_methods, :perform!
  end

  test "perform! short-circuits with nil when the product has no stampable PDFs" do
    purchase = Object.new
    link = Object.new
    link.define_singleton_method(:has_stampable_pdfs?) { false }
    purchase.define_singleton_method(:link) { link }

    assert_nil PdfStampingService::StampForPurchase.perform!(purchase)
  end

  # TODO: end-to-end stamping flow downloads each PDF from S3, stamps every
  # page via CombinePDF, re-uploads, and marks the UrlRedirect done. That
  # requires real MinIO/S3 plus a stamped-PDF fixture corpus. Out of scope
  # for the fixture-only Minitest lane. Original:
  # spec/services/pdf_stamping_service/stamp_for_purchase_spec.rb
end
