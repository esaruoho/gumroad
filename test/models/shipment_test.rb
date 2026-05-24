# frozen_string_literal: true

require "test_helper"

class ShipmentTest < ActiveSupport::TestCase
  setup do
    @purchase = purchases(:auto_invoice_enabled_purchase)
  end

  def create_shipment(**attrs)
    Shipment.create!({ purchase: @purchase }.merge(attrs))
  end

  test "shipped? returns false when shipped_at is nil" do
    refute create_shipment.shipped?
  end

  test "shipped? returns true when shipped_at is present" do
    assert create_shipment(shipped_at: 1.day.ago).shipped?
  end

  test "mark_shipped marks a shipment as shipped" do
    shipment = create_shipment
    shipment.mark_shipped
    assert shipment.shipped?
  end

  test "mark_shipped notifies sender via CustomerLowPriorityMailer" do
    shipment = create_shipment
    received_args = nil
    mail_double = Object.new
    mail_double.define_singleton_method(:deliver_later) { |*_args, **_opts| nil }
    CustomerLowPriorityMailer.stub(:order_shipped, ->(*args) { received_args = args; mail_double }) do
      shipment.mark_shipped
    end
    refute_nil received_args, "Expected CustomerLowPriorityMailer.order_shipped to be invoked"
  end

  # --- #calculated_tracking_url ---

  test "calculated_tracking_url returns the tracking_url if present" do
    s = create_shipment(tracking_number: "1234567890", carrier: "USPS", tracking_url: "https://tools.usps.com/go/TrackConfirmAction?qtc_tLabels1=1234567890")
    assert_equal "https://tools.usps.com/go/TrackConfirmAction?qtc_tLabels1=1234567890", s.calculated_tracking_url
  end

  test "calculated_tracking_url builds from carrier mapping" do
    s = create_shipment(tracking_number: "1234567890", carrier: "USPS")

    s.update!(carrier: "USPS")
    assert_equal "https://tools.usps.com/go/TrackConfirmAction?qtc_tLabels1=1234567890", s.calculated_tracking_url

    s.update!(carrier: "UPS")
    assert_equal "http://wwwapps.ups.com/WebTracking/processInputRequest?TypeOfInquiryNumber=T&InquiryNumber1=1234567890", s.calculated_tracking_url

    s.update!(carrier: "FedEx")
    assert_equal "http://www.fedex.com/Tracking?language=english&cntry_code=us&tracknumbers=1234567890", s.calculated_tracking_url

    s.update!(carrier: "DHL")
    assert_equal "http://www.dhl.com/content/g0/en/express/tracking.shtml?brand=DHL&AWB=1234567890", s.calculated_tracking_url

    s.update!(carrier: "OnTrac")
    assert_equal "http://www.ontrac.com/trackres.asp?tracking_number=1234567890", s.calculated_tracking_url

    s.update!(carrier: "Canada Post")
    assert_equal "https://www.canadapost.ca/cpotools/apps/track/personal/findByTrackNumber?LOCALE=en&trackingNumber=1234567890", s.calculated_tracking_url
  end

  test "calculated_tracking_url returns nil when no tracking_url and no carrier" do
    s = create_shipment(tracking_number: "1234567890", carrier: "USPS")
    s.update!(carrier: nil)
    assert_nil s.calculated_tracking_url
  end

  test "calculated_tracking_url returns nil when no tracking_url and no tracking_number" do
    s = create_shipment(tracking_number: "1234567890", carrier: "USPS")
    s.update!(tracking_number: nil)
    assert_nil s.calculated_tracking_url
  end

  test "calculated_tracking_url returns nil for unrecognized carrier" do
    s = create_shipment(tracking_number: "1234567890", carrier: "USPS")
    s.update!(carrier: "AnishOnTime")
    assert_nil s.calculated_tracking_url
  end
end
