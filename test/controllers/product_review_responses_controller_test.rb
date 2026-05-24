# frozen_string_literal: true

require "test_helper"

class ProductReviewResponsesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "PATCH update redirects to login when not authenticated" do
    patch :update, params: { id: "any", message: "Thanks" }
    assert_response :redirect
  end

  test "DELETE destroy redirects to login when not authenticated" do
    delete :destroy, params: { id: "any" }
    assert_response :redirect
  end
end
