# frozen_string_literal: true

require "test_helper"

class ThumbnailsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @seller = users(:named_seller)
    @seller.save! if @seller.external_id.blank?
    sign_in @seller
    @product = @seller.links.first
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "POST create returns bad_request when :thumbnail param is missing or not a hash" do
    skip "named_seller has no product fixture" if @product.nil?
    post :create, params: { link_id: @product.unique_permalink, thumbnail: "not-a-hash" }
    assert_response :bad_request
    body = response.parsed_body
    assert_equal false, body["success"]
    assert_match(/Invalid thumbnail parameter/, body["error"])
  end

  test "POST create with missing product raises a RoutingError (e404)" do
    assert_raises(ActionController::RoutingError) do
      post :create, params: { link_id: "definitely-not-a-real-id", thumbnail: { signed_blob_id: "x" } }
    end
  end
end
