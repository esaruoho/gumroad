# frozen_string_literal: true

require "test_helper"

class Api::Internal::Grmc::WebhookControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @body = { job_id: "abc123", status: "success" }
    @json_body = @body.to_json
    HandleGrmcCallbackJob.jobs.clear
  end

  def sign_request(timestamp, json)
    hmac = OpenSSL::HMAC.hexdigest("sha256", GlobalConfig.get("GRMC_WEBHOOK_SECRET"), json)
    @request.headers["Grmc-Signature"] = "t=#{timestamp},v0=#{hmac}"
    @request.headers["Content-Type"] = "application/json"
  end

  test "inherits from Api::Internal::BaseController" do
    assert_equal Api::Internal::BaseController, Api::Internal::Grmc::WebhookController.superclass
  end

  test "enqueues job on valid signature" do
    sign_request((1.second.ago.to_f * 1000).to_i, @json_body)
    post :handle, body: @json_body

    assert_empty response.body
    assert_response :ok
    assert_equal 1, HandleGrmcCallbackJob.jobs.size
    assert_equal [@body.stringify_keys], HandleGrmcCallbackJob.jobs.last["args"]
  end

  test "errors if the timestamp is empty" do
    sign_request("", @json_body)
    post :handle, body: @json_body
    assert_response :unauthorized
    assert_empty HandleGrmcCallbackJob.jobs
  end

  test "errors if the timestamp is invalid" do
    sign_request((1.day.ago.to_f * 1000).to_i, @json_body)
    post :handle, body: @json_body
    assert_response :unauthorized
    assert_empty HandleGrmcCallbackJob.jobs
  end

  test "errors if the signature header is empty" do
    post :handle, body: @json_body
    assert_response :unauthorized
    assert_empty HandleGrmcCallbackJob.jobs
  end

  test "errors if the header signature is invalid" do
    @request.headers["Grmc-Signature"] = "invalid-string"
    @request.headers["Content-Type"] = "application/json"
    post :handle, body: @json_body
    assert_response :unauthorized
    assert_empty HandleGrmcCallbackJob.jobs
  end

  test "errors if the signature is invalid" do
    sign_request((1.second.ago.to_f * 1000).to_i, "{\"something\":\"else\"}")
    post :handle, body: @json_body
    assert_response :unauthorized
    assert_empty HandleGrmcCallbackJob.jobs
  end
end
