# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class Collaborators::IncomingsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @seller.save(validate: false) if @seller.external_id.blank?
    sign_in_as_seller(@seller)
    @request.headers["X-Inertia"] = "true"
  end

  teardown { restore_protect_against_forgery! }

  test "GET index renders the Collaborators/Incomings/Index inertia component" do
    get :index
    assert_response :success
    page = JSON.parse(@response.body)
    assert_equal "Collaborators/Incomings/Index", page["component"]
  end

  test "GET accept returns 404 for non-existent invitation" do
    assert_raises(ActionController::RoutingError) do
      put :accept, params: { id: "does-not-exist" }
    end
  end
end
