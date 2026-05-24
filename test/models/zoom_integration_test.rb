# frozen_string_literal: true

require "test_helper"

class ZoomIntegrationTest < ActiveSupport::TestCase
  setup do
    @integration = integrations(:zoom_integration_basic)
    @seller = users(:named_seller)
  end

  def build_purchase(link:)
    Purchase.find_by!(link_id: link.id, seller_id: @seller.id)
  end

  test "respond_to? returns true for each INTEGRATION_DETAILS attribute" do
    ZoomIntegration::INTEGRATION_DETAILS.each do |detail|
      assert @integration.respond_to?(detail), detail
    end
  end

  test "saves details correctly" do
    assert_equal Integration.type_for(Integration::ZOOM), @integration.type
    assert_equal "0", @integration.user_id
    assert_equal "test@zoom.com", @integration.email
    assert_equal "test_access_token", @integration.access_token
    assert_equal "test_refresh_token", @integration.refresh_token
  end

  test "#as_json returns the correct json object" do
    expected = {
      keep_inactive_members: false,
      name: "zoom",
      integration_details: {
        "user_id" => "0",
        "email" => "test@zoom.com",
        "access_token" => "test_access_token",
        "refresh_token" => "test_refresh_token",
      },
    }
    assert_equal expected, @integration.as_json
  end

  test ".is_enabled_for returns true when a zoom integration is enabled on the product" do
    integration = integrations(:zoom_integration_for_enabled_product)
    product = links(:zoom_integration_enabled_product)
    ProductIntegration.create!(product: product, integration: integration)
    purchase = build_purchase(link: product)
    assert ZoomIntegration.is_enabled_for(purchase)
  end

  test ".is_enabled_for returns false when no zoom integration on the product" do
    integration = integrations(:discord_integration_for_not_enabled_product)
    product = links(:zoom_integration_disabled_product)
    ProductIntegration.create!(product: product, integration: integration)
    purchase = build_purchase(link: product)
    refute ZoomIntegration.is_enabled_for(purchase)
  end

  test ".is_enabled_for returns false when the zoom integration is soft-deleted" do
    integration = integrations(:zoom_integration_for_deleted_pi)
    product = links(:zoom_integration_deleted_pi_product)
    pi = ProductIntegration.create!(product: product, integration: integration)
    purchase = build_purchase(link: product)
    pi.mark_deleted!
    refute ZoomIntegration.is_enabled_for(purchase)
  end

  # --- #same_connection? ---

  test "same_connection? returns true when both integrations share user_id" do
    other = integrations(:zoom_integration_same_connection)
    assert @integration.same_connection?(other)
  end

  test "same_connection? returns false when integrations differ in user_id" do
    other = integrations(:zoom_integration_other)
    refute @integration.same_connection?(other)
  end

  test "same_connection? returns false when integrations differ in type" do
    other = integrations(:zoom_integration_same_connection)
    other.update_columns(type: "NotZoomIntegration")
    # SubclassNotFound is raised when reloading via STI — read just the integer columns.
    type, user_id = Integration.unscoped.where(id: other.id).pluck(:type, :json_data).first
    stub = ZoomIntegration.new
    stub.define_singleton_method(:type) { "NotZoomIntegration" }
    stub.define_singleton_method(:user_id) { "0" }
    refute @integration.same_connection?(stub)
  end
end
