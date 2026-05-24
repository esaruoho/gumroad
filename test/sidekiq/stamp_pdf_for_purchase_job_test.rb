# frozen_string_literal: true

require "test_helper"

class StampPdfForPurchaseJobTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @purchase = purchases(:pdf_stamping_purchase)
    @stamped_for = []
    @stamping_stub = ->(purchase) { @stamped_for << purchase }
  end

  test "performs the job" do
    PdfStampingService.stub(:stamp_for_purchase!, @stamping_stub) do
      StampPdfForPurchaseJob.new.perform(@purchase.id)
    end

    assert_equal [@purchase], @stamped_for
  end

  test "enqueues files ready email when notify flag is true" do
    @purchase.create_url_redirect! if @purchase.url_redirect.blank?

    PdfStampingService.stub(:stamp_for_purchase!, @stamping_stub) do
      assert_enqueued_email_with(CustomerMailer, :files_ready_for_download, args: [@purchase.id], queue: "critical") do
        StampPdfForPurchaseJob.new.perform(@purchase.id, true)
      end
    end
  end

  test "logs and does not raise when stamping fails with a known error" do
    raising = ->(_) { raise PdfStampingService::Error, "boom" }
    logged = []
    logger_stub = Object.new
    logger_stub.define_singleton_method(:error) { |msg| logged << msg }

    PdfStampingService.stub(:stamp_for_purchase!, raising) do
      Rails.stub(:logger, logger_stub) do
        assert_nothing_raised do
          StampPdfForPurchaseJob.new.perform(@purchase.id)
        end
      end
    end

    assert logged.any? { |m| m.include?("Failed stamping for purchase #{@purchase.id}") }, "expected error log; got #{logged.inspect}"
  end

  test "raises when stamping fails with an unknown error" do
    raising = ->(_) { raise StandardError, "kaboom" }
    PdfStampingService.stub(:stamp_for_purchase!, raising) do
      assert_raises(StandardError) do
        StampPdfForPurchaseJob.new.perform(@purchase.id)
      end
    end
  end
end
