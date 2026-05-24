# frozen_string_literal: true

require "test_helper"

class DiscoverControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @request.headers["X-Inertia"] = "true"
  end

  test "GET index autocomplete-only request renders Discover/Index with autocomplete_results" do
    @controller.define_singleton_method(:autocomplete_only_request?) { true }
    @controller.define_singleton_method(:autocomplete_results_data) { [] }
    get :index, params: { query: "" }
    assert_response :success
    page = JSON.parse(@response.body)
    assert_equal "Discover/Index", page["component"]
    assert_kind_of Array, page["props"]["autocomplete_results"]
  end
end
