require "test_helper"

class CircleIntegrationTest < ActiveSupport::TestCase
  def build_circle(attrs = {})
    CircleIntegration.new({
      api_key: GlobalConfig.get("CIRCLE_API_KEY"),
      community_id: "3512",
      space_group_id: "43576",
    }.merge(attrs))
  end

  def build_discord(attrs = {})
    DiscordIntegration.new({
      server_id: "0",
      server_name: "Gaming",
      username: "gumbot",
    }.merge(attrs))
  end

  test "creates the correct json details" do
    integration = build_circle
    integration.save!
    CircleIntegration::INTEGRATION_DETAILS.each do |detail|
      assert_equal true, integration.respond_to?(detail)
    end
  end

  test "saves details correctly" do
    integration = build_circle(community_id: "0", space_group_id: "0", keep_inactive_members: true)
    integration.save!
    assert_equal Integration.type_for(Integration::CIRCLE), integration.type
    assert_equal "0", integration.community_id
    assert_equal "0", integration.space_group_id
    assert_equal true, integration.keep_inactive_members
  end

  test "#as_json returns the correct json object" do
    integration = build_circle
    integration.save!
    assert_equal(
      {
        api_key: GlobalConfig.get("CIRCLE_API_KEY"),
        keep_inactive_members: false,
        name: "circle",
        integration_details: {
          "community_id" => "3512",
          "space_group_id" => "43576",
        },
      },
      integration.as_json
    )
  end

  test ".is_enabled_for returns true if a circle integration is enabled on the product" do
    product = links(:named_seller_product)
    product.product_integrations.destroy_all
    integration = build_circle
    integration.save!
    product.active_integrations << integration
    purchase = Purchase.new(link: product)
    assert_equal true, CircleIntegration.is_enabled_for(purchase)
  end

  test ".is_enabled_for returns false if a circle integration is not enabled on the product" do
    product = links(:basic_user_product)
    product.product_integrations.destroy_all
    integration = build_discord
    integration.save!
    product.active_integrations << integration
    purchase = Purchase.new(link: product)
    assert_equal false, CircleIntegration.is_enabled_for(purchase)
  end

  test ".is_enabled_for returns false if a deleted circle integration exists on the product" do
    product = links(:named_seller_product)
    product.product_integrations.destroy_all
    integration = build_circle
    integration.save!
    product.active_integrations << integration
    purchase = Purchase.new(link: product)
    product.product_integrations.reload.first.mark_deleted!
    assert_equal false, CircleIntegration.is_enabled_for(purchase)
  end
end
