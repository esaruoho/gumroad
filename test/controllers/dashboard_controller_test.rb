# frozen_string_literal: true

require "test_helper"

class DashboardControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "GET customers_count returns 404 JSON when not authenticated" do
    get :customers_count, format: :json
    assert_response :not_found
  end

  test "GET total_revenue returns 404 JSON when not authenticated" do
    get :total_revenue, format: :json
    assert_response :not_found
  end
end
