# frozen_string_literal: true

require "test_helper"

class DisputeEvidence::GenerateAccessActivityLogsServiceTest < ActiveSupport::TestCase
  setup do
    @purchase = purchases(:named_seller_call_purchase)
  end

  def make_email_info(state:, **attrs)
    email_info = CustomerEmailInfo.new(
      email_name: SendgridEventInfo::RECEIPT_MAILER_METHOD,
      purchase_id: @purchase.id,
      state: state,
    )
    attrs.each { |k, v| email_info[k] = v }
    email_info.save!
    email_info
  end

  def make_consumption_event(consumed_at:, ip_address: "0.0.0.0", event_type: ConsumptionEvent::EVENT_TYPE_WATCH, platform: Platform::WEB)
    ConsumptionEvent.create!(
      url_redirect_id: @purchase.url_redirect.id,
      purchase_id: @purchase.id,
      link_id: @purchase.link_id,
      consumed_at: consumed_at,
      ip_address: ip_address,
      event_type: event_type,
      platform: platform,
    )
  end

  test ".perform returns combined rental_activity, usage_activity, and email_activity" do
    sent_at = DateTime.parse("2024-05-07")
    rental_first_viewed_at = DateTime.parse("2024-05-08")
    consumed_at = DateTime.parse("2024-05-08")

    @purchase.create_url_redirect!
    make_email_info(
      state: :opened,
      sent_at: sent_at,
      delivered_at: sent_at + 1.hour,
      opened_at: sent_at + 2.hours,
    )
    @purchase.url_redirect.update!(rental_first_viewed_at: rental_first_viewed_at)
    make_consumption_event(consumed_at: consumed_at)

    result = DisputeEvidence::GenerateAccessActivityLogsService.perform(@purchase)
    expected = <<~TEXT.strip_heredoc.rstrip
      The receipt email was sent at 2024-05-07 00:00:00 UTC, delivered at 2024-05-07 01:00:00 UTC, opened at 2024-05-07 02:00:00 UTC.

      The rented content was first viewed at 2024-05-08 00:00:00 UTC.

      The customer accessed the product 1 time.

      consumed_at,event_type,platform,ip_address
      2024-05-08 00:00:00 UTC,watch,web,0.0.0.0
    TEXT
    assert_equal expected, result
  end

  test "#rental_activity without url_redirect returns nil" do
    assert_nil DisputeEvidence::GenerateAccessActivityLogsService.new(@purchase).send(:rental_activity)
  end

  test "#rental_activity with url_redirect but not viewed returns nil" do
    @purchase.create_url_redirect!
    assert_nil DisputeEvidence::GenerateAccessActivityLogsService.new(@purchase).send(:rental_activity)
  end

  test "#rental_activity with rental viewed returns appropriate content" do
    @purchase.create_url_redirect!
    @purchase.url_redirect.update!(rental_first_viewed_at: DateTime.parse("2024-05-07"))
    result = DisputeEvidence::GenerateAccessActivityLogsService.new(@purchase).send(:rental_activity)
    assert_equal "The rented content was first viewed at 2024-05-07 00:00:00 UTC.", result
  end

  test "#usage_activity without url_redirect returns nil" do
    assert_nil DisputeEvidence::GenerateAccessActivityLogsService.new(@purchase).send(:usage_activity)
  end

  test "#usage_activity with url_redirect and no usage returns nil" do
    @purchase.create_url_redirect!
    assert_nil DisputeEvidence::GenerateAccessActivityLogsService.new(@purchase).send(:usage_activity)
  end

  test "#usage_activity with uses set on url_redirect returns usage from url_redirect" do
    @purchase.create_url_redirect!
    @purchase.url_redirect.update!(uses: 2)
    result = DisputeEvidence::GenerateAccessActivityLogsService.new(@purchase).send(:usage_activity)
    assert_equal "The customer accessed the product 2 times.", result
  end

  test "#usage_activity with single consumption event returns content" do
    @purchase.create_url_redirect!
    consumed_at = DateTime.parse("2024-05-07")
    make_consumption_event(consumed_at: consumed_at)

    result = DisputeEvidence::GenerateAccessActivityLogsService.new(@purchase).send(:usage_activity)
    expected = <<~TEXT.strip_heredoc.rstrip
      The customer accessed the product 1 time.

      consumed_at,event_type,platform,ip_address
      2024-05-07 00:00:00 UTC,watch,web,0.0.0.0
    TEXT
    assert_equal expected, result
  end

  test "#usage_activity sorts events chronologically" do
    @purchase.create_url_redirect!
    consumed_at = DateTime.parse("2024-05-07")
    make_consumption_event(consumed_at: consumed_at)
    make_consumption_event(
      consumed_at: consumed_at - 15.hours,
      event_type: ConsumptionEvent::EVENT_TYPE_DOWNLOAD,
    )

    result = DisputeEvidence::GenerateAccessActivityLogsService.new(@purchase).send(:usage_activity)
    expected = <<~TEXT.strip_heredoc.rstrip
      The customer accessed the product 2 times.

      consumed_at,event_type,platform,ip_address
      2024-05-06 09:00:00 UTC,download,web,0.0.0.0
      2024-05-07 00:00:00 UTC,watch,web,0.0.0.0
    TEXT
    assert_equal expected, result
  end

  test "#usage_activity limits content to the last 10 events" do
    @purchase.create_url_redirect!
    consumed_at = DateTime.parse("2024-05-07")
    make_consumption_event(consumed_at: consumed_at)
    make_consumption_event(
      consumed_at: consumed_at - 15.hours,
      event_type: ConsumptionEvent::EVENT_TYPE_DOWNLOAD,
    )
    DisputeEvidence::GenerateAccessActivityLogsService::LOG_RECORDS_LIMIT.times do |i|
      make_consumption_event(
        consumed_at: consumed_at - i.hour,
        platform: Platform::IPHONE,
      )
    end

    result = DisputeEvidence::GenerateAccessActivityLogsService.new(@purchase).send(:usage_activity)
    expected = <<~TEXT.strip_heredoc.rstrip
      The customer accessed the product 12 times. Most recent 10 log records:

      consumed_at,event_type,platform,ip_address
      2024-05-06 09:00:00 UTC,download,web,0.0.0.0
      2024-05-06 15:00:00 UTC,watch,iphone,0.0.0.0
      2024-05-06 16:00:00 UTC,watch,iphone,0.0.0.0
      2024-05-06 17:00:00 UTC,watch,iphone,0.0.0.0
      2024-05-06 18:00:00 UTC,watch,iphone,0.0.0.0
      2024-05-06 19:00:00 UTC,watch,iphone,0.0.0.0
      2024-05-06 20:00:00 UTC,watch,iphone,0.0.0.0
      2024-05-06 21:00:00 UTC,watch,iphone,0.0.0.0
      2024-05-06 22:00:00 UTC,watch,iphone,0.0.0.0
      2024-05-06 23:00:00 UTC,watch,iphone,0.0.0.0
    TEXT
    assert_equal expected, result
  end

  test "#email_activity without customer_email_infos returns nil" do
    assert_nil DisputeEvidence::GenerateAccessActivityLogsService.new(@purchase).send(:email_activity)
  end

  test "#email_activity when email info not delivered returns appropriate content" do
    sent_at = DateTime.parse("2024-05-07")
    make_email_info(state: :sent, sent_at: sent_at)

    result = DisputeEvidence::GenerateAccessActivityLogsService.new(@purchase).send(:email_activity)
    assert_equal "The receipt email was sent at 2024-05-07 00:00:00 UTC.", result
  end

  test "#email_activity when email info is delivered returns appropriate content" do
    sent_at = DateTime.parse("2024-05-07")
    make_email_info(state: :delivered, sent_at: sent_at, delivered_at: sent_at + 1.hour)

    result = DisputeEvidence::GenerateAccessActivityLogsService.new(@purchase).send(:email_activity)
    assert_equal "The receipt email was sent at 2024-05-07 00:00:00 UTC, delivered at 2024-05-07 01:00:00 UTC.", result
  end

  test "#email_activity when email info is opened returns appropriate content" do
    sent_at = DateTime.parse("2024-05-07")
    make_email_info(state: :opened, sent_at: sent_at, delivered_at: sent_at + 1.hour, opened_at: sent_at + 2.hours)

    result = DisputeEvidence::GenerateAccessActivityLogsService.new(@purchase).send(:email_activity)
    assert_equal "The receipt email was sent at 2024-05-07 00:00:00 UTC, delivered at 2024-05-07 01:00:00 UTC, opened at 2024-05-07 02:00:00 UTC.", result
  end

  test "#email_activity when associated with a charge returns appropriate content" do
    seller = users(:named_seller)
    sent_at = DateTime.parse("2024-05-07")
    order = Order.create!(purchaser: @purchase.purchaser)
    charge = Charge.create!(
      order: order,
      seller: seller,
      processor: StripeChargeProcessor.charge_processor_id,
      amount_cents: 100,
      gumroad_amount_cents: 0,
      processor_fee_cents: 0,
    )
    order.purchases << @purchase
    charge.purchases << @purchase

    email_info = CustomerEmailInfo.new(
      email_name: SendgridEventInfo::RECEIPT_MAILER_METHOD,
      purchase_id: nil,
      state: :opened,
      sent_at: sent_at,
      delivered_at: sent_at + 1.hour,
      opened_at: sent_at + 2.hours,
      email_info_charge_attributes: { charge_id: charge.id },
    )
    email_info.save!

    result = DisputeEvidence::GenerateAccessActivityLogsService.new(@purchase).send(:email_activity)
    assert_equal "The receipt email was sent at 2024-05-07 00:00:00 UTC, delivered at 2024-05-07 01:00:00 UTC, opened at 2024-05-07 02:00:00 UTC.", result
  end
end
