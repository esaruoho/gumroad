# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class Workflows::EmailsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @admin = users(:admin_for_named_seller)
    sign_in_as_seller(@admin, @seller)
    @workflow = workflows(:workflows_presenter_seller)
    @workflow.save! if @workflow.external_id.blank?
  end

  teardown { restore_protect_against_forgery! }

  test "inherits from Sellers::BaseController" do
    assert_includes Workflows::EmailsController.ancestors, Sellers::BaseController
  end

  test "GET index renders Workflows/Emails/Index" do
    get :index, params: { workflow_id: @workflow.external_id }
    assert_response :success
    page = JSON.parse(CGI.unescapeHTML(@response.body.match(/data-page="([^"]*)"/)[1]))
    assert_equal "Workflows/Emails/Index", page["component"]
    assert page["props"]["workflow"].present?
    assert page["props"]["context"].present?
  end

  test "GET index returns 404 when workflow doesn't exist" do
    assert_raises(ActionController::RoutingError) do
      get :index, params: { workflow_id: "nonexistent-#{SecureRandom.hex(4)}" }
    end
  end
end
