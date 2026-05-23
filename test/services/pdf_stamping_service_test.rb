# frozen_string_literal: true

require "test_helper"

class PdfStampingServiceTest < ActiveSupport::TestCase
  test ".can_stamp_file? calls PdfStampingService::Stamp with the product file" do
    product_file = Object.new
    received_product_file = nil

    PdfStampingService::Stamp.stub(:can_stamp_file?, ->(product_file:) {
      received_product_file = product_file
      true
    }) do
      PdfStampingService.can_stamp_file?(product_file:)
    end

    assert_same product_file, received_product_file
  end

  test ".can_stamp_file? returns the result from PdfStampingService::Stamp" do
    product_file = Object.new

    PdfStampingService::Stamp.stub(:can_stamp_file?, true) do
      assert_equal true, PdfStampingService.can_stamp_file?(product_file:)
    end
  end

  test ".stamp_for_purchase! calls PdfStampingService::StampForPurchase with the purchase" do
    purchase = Object.new
    received_purchase = nil

    PdfStampingService::StampForPurchase.stub(:perform!, ->(purchase_arg) {
      received_purchase = purchase_arg
      true
    }) do
      PdfStampingService.stamp_for_purchase!(purchase)
    end

    assert_same purchase, received_purchase
  end

  test ".stamp_for_purchase! returns the result from PdfStampingService::StampForPurchase" do
    purchase = Object.new

    PdfStampingService::StampForPurchase.stub(:perform!, true) do
      assert_equal true, PdfStampingService.stamp_for_purchase!(purchase)
    end
  end

  test ".cache_key_for_purchase returns the correct cache key format for a given purchase ID" do
    assert_equal "stamp_pdf_for_purchase_job_12345", PdfStampingService.cache_key_for_purchase(12_345)
  end
end
