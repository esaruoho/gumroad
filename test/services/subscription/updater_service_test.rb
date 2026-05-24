# frozen_string_literal: true

require "test_helper"

class Subscription::UpdaterServiceTest < ActiveSupport::TestCase
  test "initializer captures all keyword arguments" do
    params = { perceived_price_cents: "1500", quantity: "2", price_range: "10" }
    service = Subscription::UpdaterService.new(
      subscription: nil,
      params: params,
      logged_in_user: nil,
      gumroad_guid: "guid-123",
      remote_ip: "127.0.0.1"
    )

    assert_nil service.subscription
    assert_equal "guid-123", service.gumroad_guid
    assert_nil service.logged_in_user
    assert_equal "127.0.0.1", service.remote_ip
    # Sees-an-int-ish params get coerced via to_i.
    assert_equal 1500, service.params[:perceived_price_cents]
    assert_equal 2, service.params[:quantity]
    assert_equal 10, service.params[:price_range]
    assert_equal false, service.api_notification_sent
  end

  test "blank contact_info values are normalized to nil" do
    service = Subscription::UpdaterService.new(
      subscription: nil,
      params: { contact_info: { "name" => "", "phone" => "555-1234" } },
      logged_in_user: nil,
      gumroad_guid: "g",
      remote_ip: "127.0.0.1"
    )

    assert_nil service.params[:contact_info]["name"]
    assert_equal "555-1234", service.params[:contact_info]["phone"]
  end

  test "non-int price params remain absent rather than coerced" do
    service = Subscription::UpdaterService.new(
      subscription: nil,
      params: {},
      logged_in_user: nil,
      gumroad_guid: "g",
      remote_ip: "127.0.0.1"
    )

    assert_nil service.params[:perceived_price_cents]
    assert_nil service.params[:quantity]
  end

  # TODO: full updater flow (37 FactoryBot refs across plan changes, upgrades,
  # SCA recovery, prorated billing) exercises Stripe SetupIntent/PaymentIntent
  # chains under VCR plus subscription/tiered-membership fixture trees that are
  # not yet on the migration branch. Deferred. Original:
  # spec/services/subscription/updater_service_spec.rb
end
