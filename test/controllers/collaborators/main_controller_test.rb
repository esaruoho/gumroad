# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class Collaborators::MainControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @seller.save(validate: false) if @seller.external_id.blank?
    sign_in_as_seller(@seller)
    @request.headers["X-Inertia"] = "true"
  end

  teardown { restore_protect_against_forgery! }

  test "GET index renders the Collaborators/Index inertia component" do
    get :index
    assert_response :success
    page = JSON.parse(@response.body)
    assert_equal "Collaborators/Index", page["component"]
  end

  test "GET new renders the Collaborators/New inertia component" do
    get :new
    assert_response :success
    page = JSON.parse(@response.body)
    assert_equal "Collaborators/New", page["component"]
  end

  test "GET edit returns 404 for non-existent collaborator" do
    assert_raises(ActionController::RoutingError) do
      get :edit, params: { id: "does-not-exist" }
    end
  end
end
