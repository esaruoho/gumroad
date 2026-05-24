# frozen_string_literal: true

require "test_helper"

class SendPurchaseReceiptJobTest < ActiveSupport::TestCase
  setup do
    @prepended_modules = []
    @purchase = purchases(:pdf_stamping_purchase)
    @stamping_calls = []
    @receipt_calls = []
    @stamp_stub = ->(p) { @stamping_calls << p }
  end

  teardown do
    @prepended_modules.each { |mod, _klass| mod.module_eval { instance_methods(false).each { |m| remove_method(m) } } }
  end

  def stub_instance_method(klass, method, &block)
    mod = Module.new
    mod.send(:define_method, method, &block)
    klass.prepend(mod)
    @prepended_modules << [mod, klass]
  end

  def mailer_double
    mock = Minitest::Mock.new
    mock.expect(:deliver_now, nil)
    mock
  end

  test "stamps the PDFs and delivers the email when product has stampable PDFs" do
    stub_instance_method(Link, :has_stampable_pdfs?) { true }
    mailer = mailer_double
    PdfStampingService.stub(:stamp_for_purchase!, @stamp_stub) do
      CustomerMailer.stub(:receipt, ->(pid) { @receipt_calls << pid; mailer }) do
        SendPurchaseReceiptJob.new.perform(@purchase.id)
      end
    end
    assert_equal [@purchase], @stamping_calls
    assert_equal [@purchase.id], @receipt_calls
    assert mailer.verify
  end

  test "raises and does not deliver email when stamping fails" do
    stub_instance_method(Link, :has_stampable_pdfs?) { true }
    raising = ->(_) { raise PdfStampingService::Error, "boom" }
    PdfStampingService.stub(:stamp_for_purchase!, raising) do
      CustomerMailer.stub(:receipt, ->(pid) { @receipt_calls << pid; mailer_double }) do
        assert_raises(PdfStampingService::Error) do
          SendPurchaseReceiptJob.new.perform(@purchase.id)
        end
      end
    end
    assert_empty @receipt_calls
  end

  test "delivers the email and does not stamp when product has no stampable PDFs" do
    stub_instance_method(Link, :has_stampable_pdfs?) { false }
    mailer = mailer_double
    PdfStampingService.stub(:stamp_for_purchase!, @stamp_stub) do
      CustomerMailer.stub(:receipt, ->(pid) { @receipt_calls << pid; mailer }) do
        SendPurchaseReceiptJob.new.perform(@purchase.id)
      end
    end
    assert_empty @stamping_calls
    assert_equal [@purchase.id], @receipt_calls
    assert mailer.verify
  end

  test "does not deliver email when purchase is a bundle product purchase" do
    stub_instance_method(Purchase, :is_bundle_product_purchase?) { true }
    stub_instance_method(Link, :has_stampable_pdfs?) { false }
    CustomerMailer.stub(:receipt, ->(pid) { @receipt_calls << pid; mailer_double }) do
      SendPurchaseReceiptJob.new.perform(@purchase.id)
    end
    assert_empty @receipt_calls
  end
end
