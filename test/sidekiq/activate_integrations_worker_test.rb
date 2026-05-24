# frozen_string_literal: true

require "test_helper"

class ActivateIntegrationsWorkerTest < ActiveSupport::TestCase
  test "calls CircleIntegrationService#activate" do
    purchase = purchases(:named_seller_call_purchase)
    received = nil
    service_mock = Minitest::Mock.new
    service_mock.expect(:activate, nil) { |p| received = p; true }

    Integrations::CircleIntegrationService.stub(:new, ->() { service_mock }) do
      ActivateIntegrationsWorker.new.perform(purchase.id)
    end

    assert_equal purchase, received
    service_mock.verify
  end

  test "errors out if purchase is not found" do
    called = false
    Integrations::CircleIntegrationService.stub(:new, ->() { called = true; raise "should not be called" }) do
      assert_raises(ActiveRecord::RecordNotFound) do
        ActivateIntegrationsWorker.new.perform(1)
      end
    end
    refute called
  end
end
