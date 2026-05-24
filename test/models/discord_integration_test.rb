# frozen_string_literal: true

require "test_helper"

class DiscordIntegrationTest < ActiveSupport::TestCase
  def build_discord(server_id: "0", server_name: "Gaming", username: "gumbot")
    DiscordIntegration.new(server_id: server_id, server_name: server_name, username: username)
  end

  test "creates the correct json details" do
    integration = build_discord
    integration.save!
    DiscordIntegration::INTEGRATION_DETAILS.each do |detail|
      assert integration.respond_to?(detail), "expected to respond_to :#{detail}"
    end
  end

  test "saves details correctly" do
    integration = build_discord
    integration.save!
    assert_equal Integration.type_for(Integration::DISCORD), integration.type
    assert_equal "0", integration.server_id
    assert_equal "Gaming", integration.server_name
    assert_equal "gumbot", integration.username
    assert_equal false, integration.keep_inactive_members
  end

  test "#as_json returns the correct json object" do
    integration = build_discord
    integration.save!
    assert_equal(
      {
        keep_inactive_members: false,
        name: "discord",
        integration_details: {
          "server_id" => "0",
          "server_name" => "Gaming",
          "username" => "gumbot",
        }
      },
      integration.as_json
    )
  end

  test ".is_enabled_for returns true if a discord integration is enabled on the product" do
    product = links(:named_seller_product)
    purchase = build_minimal_purchase(product)
    integration = build_discord
    integration.save!
    ProductIntegration.create!(product: product, integration: integration)
    assert_equal true, DiscordIntegration.is_enabled_for(purchase)
  end

  test ".is_enabled_for returns false if a discord integration is not enabled on the product" do
    # named_seller_product already has CircleIntegration product_integrations (no discord).
    product = links(:named_seller_product)
    purchase = build_minimal_purchase(product)
    assert_equal false, DiscordIntegration.is_enabled_for(purchase)
  end

  test ".is_enabled_for returns false if a deleted discord integration exists on the product" do
    product = links(:named_seller_product)
    purchase = build_minimal_purchase(product)
    integration = build_discord
    integration.save!
    pi = ProductIntegration.create!(product: product, integration: integration)
    pi.mark_deleted!
    assert_equal false, DiscordIntegration.is_enabled_for(purchase)
  end

  test ".discord_user_id_for returns discord_user_id for a purchase with an enabled discord integration" do
    product = links(:named_seller_product)
    integration = build_discord
    integration.save!
    ProductIntegration.create!(product: product, integration: integration)
    purchase = build_minimal_purchase(product)
    PurchaseIntegration.create!(purchase: purchase, integration: integration, discord_user_id: "user-0")
    assert_equal "user-0", DiscordIntegration.discord_user_id_for(purchase)
  end

  test ".discord_user_id_for returns nil for a purchase without an enabled discord integration" do
    # Reuse named_seller_product (circle-only).
    product = links(:named_seller_product)
    purchase = build_minimal_purchase(product)
    assert_nil DiscordIntegration.discord_user_id_for(purchase)
  end

  test ".discord_user_id_for returns nil for a purchase without an active discord integration (deleted PurchaseIntegration)" do
    product = links(:named_seller_product)
    integration = build_discord
    integration.save!
    ProductIntegration.create!(product: product, integration: integration)
    purchase = build_minimal_purchase(product)
    PurchaseIntegration.create!(purchase: purchase, integration: integration, discord_user_id: "user-0", deleted_at: 1.day.ago)
    assert_nil DiscordIntegration.discord_user_id_for(purchase)
  end

  test ".discord_user_id_for returns nil for a purchase with a deleted discord ProductIntegration" do
    product = links(:named_seller_product)
    integration = build_discord
    integration.save!
    pi = ProductIntegration.create!(product: product, integration: integration)
    purchase = build_minimal_purchase(product)
    PurchaseIntegration.create!(purchase: purchase, integration: integration, discord_user_id: "user-0")
    pi.mark_deleted!
    assert_nil DiscordIntegration.discord_user_id_for(purchase)
  end

  test "#disconnect! disconnects bot from server if server id is valid" do
    integration = build_discord(server_id: "0")
    integration.save!
    WebMock.stub_request(:delete, "#{Discordrb::API.api_base}/users/@me/guilds/0").
      with(headers: { "Authorization" => "Bot #{DISCORD_BOT_TOKEN}" }).
      to_return(status: 204)
    assert_equal true, integration.disconnect!
  end

  test "#disconnect! fails if bot is not added to server" do
    integration = build_discord(server_id: "0")
    integration.save!
    WebMock.stub_request(:delete, "#{Discordrb::API.api_base}/users/@me/guilds/0").
      with(headers: { "Authorization" => "Bot #{DISCORD_BOT_TOKEN}" }).
      to_return(status: 404, body: { code: Discordrb::Errors::UnknownMember.code }.to_json)
    assert_equal false, integration.disconnect!
  end

  test "#disconnect! returns true if the server has been deleted" do
    integration = build_discord(server_id: "0")
    integration.save!
    WebMock.stub_request(:delete, "#{Discordrb::API.api_base}/users/@me/guilds/0").
      with(headers: { "Authorization" => "Bot #{DISCORD_BOT_TOKEN}" }).
      to_return(status: 404, body: { code: Discordrb::Errors::UnknownServer.code }.to_json)
    assert_equal true, integration.disconnect!
  end

  test "#same_connection? returns true if both integrations have the same server id" do
    a = build_discord
    a.save!
    b = build_discord
    b.save!
    assert_equal true, a.same_connection?(b)
  end

  test "#same_connection? returns false if both integrations have different server ids" do
    a = build_discord
    a.save!
    b = build_discord(server_id: "1")
    b.save!
    assert_equal false, a.same_connection?(b)
  end

  test "#same_connection? returns false if both integrations have different types" do
    a = build_discord
    a.save!
    b = build_discord
    b.save!
    b.update(type: "NotDiscordIntegration")
    assert_equal false, a.same_connection?(b)
  end

  private

  def build_minimal_purchase(product)
    purchase = Purchase.new(
      seller: product.user,
      link: product,
      email: "buyer-#{SecureRandom.hex(4)}@example.com",
      price_cents: 100,
      total_transaction_cents: 100,
      displayed_price_cents: 100,
      displayed_price_currency_type: "usd",
      purchase_state: "successful",
      succeeded_at: Time.current,
      fee_cents: 0,
    )
    purchase.save!(validate: false)
    purchase
  end
end
