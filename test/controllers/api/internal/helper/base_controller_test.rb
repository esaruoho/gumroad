# frozen_string_literal: true

require "test_helper"

class HelperBaseControllerTestController < Api::Internal::Helper::BaseController
  before_action :authorize_hmac_signature!, only: :index
  skip_before_action :authorize_helper_token!, only: :index

  def index
    render json: { success: true }
  end

  def new
    render json: { success: true }
  end
end

class Api::Internal::Helper::BaseControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include HelperAITestHelper

  tests HelperBaseControllerTestController

  setup do
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw do
      get "index" => "helper_base_controller_test#index"
      get "new" => "helper_base_controller_test#new"
    end
    @params = { email: "test@example.com", timestamp: Time.now.to_i }
  end

  # authorize_hmac_signature!

  test "returns 200 when authentication is valid and payload is in query params" do
    set_headers(params: @params)
    get :index, params: @params
    assert_response :success
    assert_equal({ success: true }.to_json, @response.body)
  end

  test "returns 200 when authentication is valid and payload is in JSON" do
    set_headers(json: @params)
    post :index, params: @params
    assert_response :success
    assert_equal({ success: true }.to_json, @response.body)
  end

  test "returns 401 when authorization token is missing" do
    get :index, params: @params
    assert_response :unauthorized
    assert_equal({ success: false, message: "unauthenticated" }.to_json, @response.body)
  end

  test "returns 401 when authorization token is invalid" do
    set_headers(params: @params.merge(email: "wrong.email@example.com"))
    get :index, params: @params
    assert_response :unauthorized
    assert_equal({ success: false, message: "authorization is invalid" }.to_json, @response.body)
  end

  test "returns 401 when timestamp is too old" do
    params = @params.merge(timestamp: (Api::Internal::Helper::BaseController::HMAC_EXPIRATION + 5.second).ago.to_i)
    set_headers(params:)
    get :index, params: params
    assert_response :unauthorized
    assert_equal({ success: false, message: "bad timestamp" }.to_json, @response.body)
  end

  test "returns 401 when timestamp is too far in the future" do
    params = @params.merge(timestamp: (Time.now + Api::Internal::Helper::BaseController::HMAC_EXPIRATION + 5.second).to_i)
    set_headers(params:)
    get :index, params: params
    assert_response :unauthorized
    assert_equal({ success: false, message: "bad timestamp" }.to_json, @response.body)
  end

  test "returns 400 when timestamp parameter is missing" do
    params = @params.except(:timestamp)
    set_headers(params:)
    get :index, params: params
    assert_response :bad_request
    assert_equal({ success: false, message: "timestamp is required" }.to_json, @response.body)
  end

  # authorize_helper_token!

  test "returns 200 when the helper token is valid" do
    request.headers["Authorization"] = "Bearer #{GlobalConfig.get("HELPER_TOOLS_TOKEN")}"
    get :new
    assert_response :success
    assert_equal({ success: true }.to_json, @response.body)
  end

  test "returns 401 when the helper token is invalid" do
    request.headers["Authorization"] = "Bearer invalid_token"
    get :new
    assert_response :unauthorized
    assert_equal({ success: false, message: "authorization is invalid" }.to_json, @response.body)
  end

  test "returns 401 when the helper token is missing" do
    get :new
    assert_response :unauthorized
    assert_equal({ success: false, message: "unauthenticated" }.to_json, @response.body)
  end
end
