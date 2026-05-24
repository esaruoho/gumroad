# frozen_string_literal: true

require "test_helper"

class PdfUnstampableNotifierJobTest < ActiveSupport::TestCase
  setup do
    @product = links(:named_seller_product)
  end

  test "no-ops when there are no PDF files needing stampability check" do
    deliveries = []
    ContactingCreatorMailer.stub(:unstampable_pdf_notification, ->(*_a) {
      mail = Object.new
      mail.define_singleton_method(:deliver_later) { |*_args, **_kw| deliveries << :unstampable }
      mail
    }) do
      PdfUnstampableNotifierJob.new.perform(@product.id)
    end
    assert_empty deliveries
  end

  test "notifies creator and enqueues stamping when files split between stampable/unstampable" do
    pdf_a = @product.product_files.create!(url: "#{S3_BASE_URL}specs/a.pdf", position: 1, filetype: "pdf",
                                            pdf_stamp_enabled: true)
    pdf_b = @product.product_files.create!(url: "#{S3_BASE_URL}specs/b.pdf", position: 2, filetype: "pdf",
                                            pdf_stamp_enabled: true)
    deliveries = []
    PdfStampingService.stub(:can_stamp_file?, ->(product_file:) { product_file.id == pdf_a.id }) do
      mail_obj = Object.new
      mail_obj.define_singleton_method(:deliver_later) { |*_args, **_kw| deliveries << :unstampable }
      ContactingCreatorMailer.stub(:unstampable_pdf_notification, ->(_id) { mail_obj }) do
        stamped_ids = []
        StampPdfForPurchaseJob.stub(:perform_async, ->(pid) { stamped_ids << pid }) do
          PdfUnstampableNotifierJob.new.perform(@product.id)
        end
        assert_equal [:unstampable], deliveries
      end
    end
    assert_equal true, pdf_a.reload.stampable_pdf
    assert_equal false, pdf_b.reload.stampable_pdf
  end

  test "all files unstampable still notifies creator but skips stamping enqueue" do
    @product.product_files.create!(url: "#{S3_BASE_URL}specs/x.pdf", position: 1, filetype: "pdf",
                                    pdf_stamp_enabled: true)
    deliveries = []
    PdfStampingService.stub(:can_stamp_file?, ->(product_file:) { false }) do
      mail_obj = Object.new
      mail_obj.define_singleton_method(:deliver_later) { |*_args, **_kw| deliveries << :unstampable }
      ContactingCreatorMailer.stub(:unstampable_pdf_notification, ->(_id) { mail_obj }) do
        stamped_ids = []
        StampPdfForPurchaseJob.stub(:perform_async, ->(pid) { stamped_ids << pid }) do
          PdfUnstampableNotifierJob.new.perform(@product.id)
        end
        assert_equal [:unstampable], deliveries
        assert_empty stamped_ids
      end
    end
  end
end
