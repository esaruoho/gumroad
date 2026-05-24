# frozen_string_literal: true

require "test_helper"

class UpdateIntegrationsOnTierChangeWorkerTest < ActiveSupport::TestCase
  test "calls #update_on_tier_change for all integrations" do
    subscription = subscriptions(:named_seller_product_subscription)
    received = { Integrations::CircleIntegrationService => [], Integrations::DiscordIntegrationService => [] }
    [Integrations::CircleIntegrationService, Integrations::DiscordIntegrationService].each do |klass|
      klass.define_method(:update_on_tier_change) { |sub| received[klass] << sub }
    end
    UpdateIntegrationsOnTierChangeWorker.new.perform(subscription.id)
    received.each_value { |arr| assert_equal [subscription], arr }
  ensure
    [Integrations::CircleIntegrationService, Integrations::DiscordIntegrationService].each do |klass|
      klass.remove_method(:update_on_tier_change) if klass.instance_methods(false).include?(:update_on_tier_change)
    end
  end

  test "errors out if subscription is not found" do
    assert_raises(ActiveRecord::RecordNotFound) do
      UpdateIntegrationsOnTierChangeWorker.new.perform(0)
    end
  end
end
