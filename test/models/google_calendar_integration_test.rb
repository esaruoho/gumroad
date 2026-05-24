# frozen_string_literal: true

require "test_helper"

class GoogleCalendarIntegrationTest < ActiveSupport::TestCase
  setup do
    @integration = integrations(:google_calendar_integration_one)
    @seller = users(:named_seller)
    @product = links(:named_seller_product)
  end

  test "exposes INTEGRATION_DETAILS accessors" do
    GoogleCalendarIntegration::INTEGRATION_DETAILS.each do |detail|
      assert @integration.respond_to?(detail), "Expected accessor ##{detail}"
    end
  end

  test "#as_json returns the correct json object" do
    assert_equal({
      keep_inactive_members: false,
      name: "google_calendar",
      integration_details: {
        "calendar_id" => "0",
        "calendar_summary" => "Holidays",
        "email" => "hi@gmail.com",
        "access_token" => "test_access_token",
        "refresh_token" => "test_refresh_token",
      },
    }, @integration.as_json)
  end

  # ---- .is_enabled_for ----

  test ".is_enabled_for returns true when integration enabled on product" do
    # named_seller_product already has circle_integration_one + circle_integration_two attached.
    # Attach our google integration too.
    ProductIntegration.create!(product: @product, integration: @integration)
    purchase = build_purchase
    assert GoogleCalendarIntegration.is_enabled_for(purchase)
  end

  test ".is_enabled_for returns false when no google_calendar integration on product" do
    # named_seller_product fixture attaches only circle integrations — no google_calendar.
    purchase = build_purchase
    refute GoogleCalendarIntegration.is_enabled_for(purchase)
  end

  test ".is_enabled_for returns false when google_calendar integration is deleted" do
    pi = ProductIntegration.create!(product: @product, integration: @integration)
    purchase = build_purchase
    pi.mark_deleted!
    refute GoogleCalendarIntegration.is_enabled_for(purchase)
  end

  # ---- #disconnect! ----

  test "#disconnect! returns true when revoke succeeds" do
    WebMock.stub_request(:post, "#{GoogleCalendarApi::GOOGLE_CALENDAR_OAUTH_URL}/revoke")
      .with(query: { token: @integration.access_token }).to_return(status: 200)
    assert_equal true, @integration.disconnect!
  end

  test "#disconnect! returns false when revoke fails" do
    WebMock.stub_request(:post, "#{GoogleCalendarApi::GOOGLE_CALENDAR_OAUTH_URL}/revoke")
      .with(query: { token: @integration.access_token }).to_return(status: 400)
    assert_equal false, @integration.disconnect!
  end

  # ---- #same_connection? ----

  test "#same_connection? returns true for integrations with the same email" do
    other = integrations(:google_calendar_integration_same_email)
    assert @integration.same_connection?(other)
  end

  test "#same_connection? returns false for different emails" do
    other = integrations(:google_calendar_integration_other_email)
    refute @integration.same_connection?(other)
  end

  test "#same_connection? returns false for different types" do
    other = integrations(:google_calendar_integration_same_email)
    other.update_column(:type, "NotGoogleCalendarIntegration")
    refute @integration.same_connection?(other)
  end

  private

  def build_purchase
    p = Purchase.new(
      seller: @seller, link: @product,
      price_cents: 100, total_transaction_cents: 100, fee_cents: 0,
      displayed_price_cents: 100, displayed_price_currency_type: "usd",
      purchase_state: "successful", succeeded_at: Time.current,
      email: "buyer-#{SecureRandom.hex(3)}@example.com"
    )
    p.save!(validate: false)
    p
  end
end
