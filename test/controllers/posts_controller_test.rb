# frozen_string_literal: true

require "test_helper"

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "POST send_for_purchase redirects to login when not authenticated" do
    post :send_for_purchase, params: { id: "x", purchase_id: "y" }
    assert_response :redirect
  end

  test "POST increment_post_views raises 404 for unknown post id" do
    assert_raises(ActionController::RoutingError) do
      post :increment_post_views, params: { id: "does-not-exist" }
    end
  end
end
