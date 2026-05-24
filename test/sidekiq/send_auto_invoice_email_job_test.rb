# frozen_string_literal: true

require "test_helper"

class SendAutoInvoiceEmailJobTest < ActiveSupport::TestCase
  def with_mailer_stub
    received = nil
    mailer_double = Minitest::Mock.new
    mailer_double.expect(:deliver_now, nil)
    CustomerMailer.stub(:auto_invoice, ->(purchase_id, charge_id) { received = [purchase_id, charge_id]; mailer_double }) do
      yield
    end
    [received, mailer_double]
  end

  test "delivers the auto_invoice mail when buyer has billing details with auto-email enabled" do
    purchase = purchases(:auto_invoice_enabled_purchase)
    received, mailer = with_mailer_stub do
      SendAutoInvoiceEmailJob.new.perform(purchase.id, nil)
    end
    assert_equal [purchase.id, nil], received
    assert mailer.verify
  end

  test "does not send the mail when buyer has no billing details" do
    purchase = purchases(:auto_invoice_no_billing_purchase)
    called = false
    CustomerMailer.stub(:auto_invoice, ->(*_args) { called = true; Minitest::Mock.new.expect(:deliver_now, nil) }) do
      SendAutoInvoiceEmailJob.new.perform(purchase.id, nil)
    end
    refute called
  end

  test "does not send the mail when buyer disabled auto-email" do
    purchase = purchases(:auto_invoice_disabled_purchase)
    called = false
    CustomerMailer.stub(:auto_invoice, ->(*_args) { called = true; Minitest::Mock.new.expect(:deliver_now, nil) }) do
      SendAutoInvoiceEmailJob.new.perform(purchase.id, nil)
    end
    refute called
  end

  test "does not send the mail when purchase has no associated logged-in buyer" do
    purchase = purchases(:auto_invoice_anonymous_purchase)
    called = false
    CustomerMailer.stub(:auto_invoice, ->(*_args) { called = true; Minitest::Mock.new.expect(:deliver_now, nil) }) do
      SendAutoInvoiceEmailJob.new.perform(purchase.id, nil)
    end
    refute called
  end
end
