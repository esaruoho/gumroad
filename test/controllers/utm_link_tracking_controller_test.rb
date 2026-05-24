# frozen_string_literal: true

require "test_helper"

class UtmLinkTrackingControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @utm_link = utm_links(:utm_link_for_named_seller)
    Feature.activate_user(:utm_links, @utm_link.seller)
  end

  teardown do
    Feature.deactivate_user(:utm_links, @utm_link.seller)
  end

  test "GET show raises routing error when :utm_links feature flag is disabled" do
    Feature.deactivate_user(:utm_links, @utm_link.seller)
    assert_raises(ActionController::RoutingError) do
      get :show, params: { permalink: @utm_link.permalink }
    end
  end

  test "GET show redirects to the utm_link's url" do
    get :show, params: { permalink: @utm_link.permalink }
    assert_redirected_to @utm_link.utm_url
  end
end
