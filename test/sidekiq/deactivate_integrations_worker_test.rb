# frozen_string_literal: true

require "test_helper"

class DeactivateIntegrationsWorkerTest < ActiveSupport::TestCase
  test "calls #deactivate for all integrations" do
    purchase = purchases(:named_seller_call_purchase)

    circle_mock = Minitest::Mock.new
    circle_mock.expect(:deactivate, nil) { |p| p == purchase }
    discord_mock = Minitest::Mock.new
    discord_mock.expect(:deactivate, nil) { |p| p == purchase }

    Integrations::CircleIntegrationService.stub(:new, ->() { circle_mock }) do
      Integrations::DiscordIntegrationService.stub(:new, ->() { discord_mock }) do
        DeactivateIntegrationsWorker.new.perform(purchase.id)
      end
    end

    circle_mock.verify
    discord_mock.verify
  end

  test "errors out if purchase is not found" do
    circle_called = false
    discord_called = false
    Integrations::CircleIntegrationService.stub(:new, ->() { circle_called = true; raise "nope" }) do
      Integrations::DiscordIntegrationService.stub(:new, ->() { discord_called = true; raise "nope" }) do
        assert_raises(ActiveRecord::RecordNotFound) do
          DeactivateIntegrationsWorker.new.perform(1)
        end
      end
    end
    refute circle_called
    refute discord_called
  end
end
