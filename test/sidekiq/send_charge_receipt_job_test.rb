# frozen_string_literal: true

require "test_helper"

class SendChargeReceiptJobTest < ActiveSupport::TestCase
  setup do
    @prepended_modules = []
    @charge = charges(:admin_charge_policy_charge)
    @charge.update_columns(receipt_sent: false) if @charge.receipt_sent?
    @stamping_calls = []
    @receipt_calls = []
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

  test "delivers the email and updates the charge without stamping when no purchases need stamping" do
    stub_instance_method(Charge, :purchases_requiring_stamping) { [] }
    mailer = mailer_double
    PdfStampingService.stub(:stamp_for_purchase!, ->(p) { @stamping_calls << p }) do
      CustomerMailer.stub(:receipt, ->(pid, cid) { @receipt_calls << [pid, cid]; mailer }) do
        SendChargeReceiptJob.new.perform(@charge.id)
      end
    end
    assert_empty @stamping_calls
    assert_equal [[nil, @charge.id]], @receipt_calls
    assert @charge.reload.receipt_sent?
    assert mailer.verify
  end

  test "does nothing when the receipt has already been sent" do
    @charge.update!(receipt_sent: true)
    PdfStampingService.stub(:stamp_for_purchase!, ->(p) { @stamping_calls << p }) do
      CustomerMailer.stub(:receipt, ->(pid, cid) { @receipt_calls << [pid, cid]; mailer_double }) do
        SendChargeReceiptJob.new.perform(@charge.id)
      end
    end
    assert_empty @stamping_calls
    assert_empty @receipt_calls
  end

  test "stamps the PDFs and delivers the email when a purchase requires stamping" do
    target_purchase = @charge.purchases.first
    stub_instance_method(Charge, :purchases_requiring_stamping) { [target_purchase] }
    mailer = mailer_double
    PdfStampingService.stub(:stamp_for_purchase!, ->(p) { @stamping_calls << p }) do
      CustomerMailer.stub(:receipt, ->(pid, cid) { @receipt_calls << [pid, cid]; mailer }) do
        SendChargeReceiptJob.new.perform(@charge.id)
      end
    end
    assert_equal [target_purchase], @stamping_calls
    assert_equal [[nil, @charge.id]], @receipt_calls
    assert @charge.reload.receipt_sent?
  end

  test "raises and does not deliver email when stamping fails" do
    target_purchase = @charge.purchases.first
    stub_instance_method(Charge, :purchases_requiring_stamping) { [target_purchase] }
    raising = ->(_) { raise PdfStampingService::Error, "boom" }
    PdfStampingService.stub(:stamp_for_purchase!, raising) do
      CustomerMailer.stub(:receipt, ->(pid, cid) { @receipt_calls << [pid, cid]; mailer_double }) do
        assert_raises(PdfStampingService::Error) do
          SendChargeReceiptJob.new.perform(@charge.id)
        end
      end
    end
    assert_empty @receipt_calls
    refute @charge.reload.receipt_sent?
  end
end
