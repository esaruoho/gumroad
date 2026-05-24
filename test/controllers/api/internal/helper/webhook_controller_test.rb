# frozen_string_literal: false

require "test_helper"

class Api::Internal::Helper::WebhookControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include HelperAITestHelper

  setup do
    @event = "conversation.created"
    @payload = { "conversation_id" => "123" }
    @params = { event: @event, payload: @payload, timestamp: Time.current.to_i }
  end

  test "inherits from Api::Internal::Helper::BaseController" do
    assert_equal Api::Internal::Helper::BaseController, Api::Internal::Helper::WebhookController.superclass
  end

  test "enqueues a HandleHelperEventWorker job with valid parameters" do
    HandleHelperEventWorker.jobs.clear
    before_size = HandleHelperEventWorker.jobs.size
    set_headers(json: @params)
    post :handle, params: @params
    assert_equal before_size + 1, HandleHelperEventWorker.jobs.size
    assert_response :success
    assert_equal({ "success" => true }, JSON.parse(@response.body))
  end

  test "returns a bad request status when event is missing" do
    params = @params.except(:event)
    set_headers(json: params)
    post :handle, params: params
    assert_response :bad_request
    assert_equal({ "success" => false, "error" => "missing required parameters" }, JSON.parse(@response.body))
  end

  test "returns a bad request status when payload is missing" do
    params = @params.except(:payload)
    set_headers(json: params)
    post :handle, params: params
    assert_response :bad_request
    assert_equal({ "success" => false, "error" => "missing required parameters" }, JSON.parse(@response.body))
  end
end
