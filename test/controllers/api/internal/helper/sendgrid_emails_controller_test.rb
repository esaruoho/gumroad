# frozen_string_literal: true

require "test_helper"

class Api::Internal::Helper::SendgridEmailsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  EMAIL = "buyer@example.com"

  setup do
    @request.headers["Authorization"] = "Bearer #{GlobalConfig.get("HELPER_TOOLS_TOKEN")}"

    @suppression_manager = Object.new
    @captured_remove_lists = nil
    @remove_return = nil
    @detailed_status_return = nil
    sm = @suppression_manager
    test_self = self

    sm.define_singleton_method(:detailed_status) { test_self.instance_variable_get(:@detailed_status_return) }
    sm.define_singleton_method(:remove_from_lists) do |lists|
      test_self.instance_variable_set(:@captured_remove_lists, lists)
      test_self.instance_variable_get(:@remove_return)
    end

    unless EmailSuppressionManager.respond_to?(:__orig_new)
      EmailSuppressionManager.singleton_class.send(:alias_method, :__orig_new, :new)
    end
    captured_sm = sm
    EmailSuppressionManager.define_singleton_method(:new) do |arg|
      raise "unexpected email #{arg}" unless arg == EMAIL
      captured_sm
    end
  end

  teardown do
    if EmailSuppressionManager.singleton_class.method_defined?(:__orig_new)
      EmailSuppressionManager.singleton_class.send(:remove_method, :new)
      EmailSuppressionManager.singleton_class.send(:alias_method, :new, :__orig_new)
      EmailSuppressionManager.singleton_class.send(:remove_method, :__orig_new)
    end
  end

  test "inherits from Api::Internal::Helper::BaseController" do
    assert_equal Api::Internal::Helper::BaseController, Api::Internal::Helper::SendgridEmailsController.superclass
  end

  # POST check_status

  test "check_status returns 400 when email is missing" do
    post :check_status
    assert_response :bad_request
    assert_equal({ "success" => false, "message" => "'email' parameter is required" }, @response.parsed_body)
  end

  test "check_status returns 401 when token is invalid" do
    @request.headers["Authorization"] = "Bearer invalid_token"
    post :check_status
    assert_response :unauthorized
    assert_equal({ success: false, message: "authorization is invalid" }.to_json, @response.body)
  end

  test "check_status returns 401 when token is missing" do
    @request.headers["Authorization"] = nil
    post :check_status
    assert_response :unauthorized
    assert_equal({ success: false, message: "unauthenticated" }.to_json, @response.body)
  end

  test "check_status returns suppressed: false with empty SendGrid buckets" do
    @detailed_status_return = { bounces: [], blocks: [], spam_reports: [], invalid_emails: [] }
    post :check_status, params: { email: EMAIL }
    assert_response :success
    body = @response.parsed_body
    assert_equal true, body["success"]
    assert_equal EMAIL, body["email"]
    assert_equal false, body["suppressed"]
    assert_equal({ "bounces" => [], "blocks" => [], "spam_reports" => [], "invalid_emails" => [] }, body["sendgrid"])
  end

  test "check_status returns suppressed: true with details" do
    @detailed_status_return = {
      bounces: [{ subuser: :gumroad, reason: "550 5.1.1 mailbox does not exist", created_at: "2025-01-15T00:00:00Z" }],
      blocks: [],
      spam_reports: [{ subuser: :creators, reason: "user marked as spam", created_at: "2025-01-15T00:00:00Z" }],
      invalid_emails: [],
    }
    post :check_status, params: { email: EMAIL }
    assert_response :success
    body = @response.parsed_body
    assert_equal true, body["success"]
    assert_equal true, body["suppressed"]
    assert_equal "gumroad", body["sendgrid"]["bounces"].first["subuser"]
    assert_equal "creators", body["sendgrid"]["spam_reports"].first["subuser"]
  end

  # POST remove_suppression

  test "remove_suppression returns 400 when email is missing" do
    post :remove_suppression
    assert_response :bad_request
  end

  test "remove_suppression returns 401 when token is invalid" do
    @request.headers["Authorization"] = "Bearer invalid_token"
    post :remove_suppression
    assert_response :unauthorized
    assert_equal({ success: false, message: "authorization is invalid" }.to_json, @response.body)
  end

  test "remove_suppression returns 401 when token is missing" do
    @request.headers["Authorization"] = nil
    post :remove_suppression
    assert_response :unauthorized
    assert_equal({ success: false, message: "unauthenticated" }.to_json, @response.body)
  end

  test "remove_suppression returns 400 when list is invalid" do
    post :remove_suppression, params: { email: EMAIL, list: "garbage" }
    assert_response :bad_request
    assert_includes @response.parsed_body["message"], "Unsupported list(s): garbage"
  end

  test "remove_suppression with no list defaults to all supported lists" do
    @remove_return = { bounces: [:gumroad], blocks: [], spam_reports: [:creators], invalid_emails: [] }
    post :remove_suppression, params: { email: EMAIL }
    assert_response :success
    assert_equal [:bounces, :blocks, :spam_reports, :invalid_emails], @captured_remove_lists
    body = @response.parsed_body
    assert_equal true, body["success"]
    assert_equal({ "bounces" => ["gumroad"], "blocks" => [], "spam_reports" => ["creators"], "invalid_emails" => [] }, body["removed_from"])
  end

  test "remove_suppression with a single list value removes from only that list" do
    @remove_return = { bounces: [:gumroad] }
    post :remove_suppression, params: { email: EMAIL, list: "bounces" }
    assert_response :success
    assert_equal [:bounces], @captured_remove_lists
    assert_equal({ "bounces" => ["gumroad"] }, @response.parsed_body["removed_from"])
  end

  test "remove_suppression with list='all' removes from every supported list" do
    @remove_return = { bounces: [], blocks: [], spam_reports: [], invalid_emails: [] }
    post :remove_suppression, params: { email: EMAIL, list: "all" }
    assert_response :success
    assert_equal [:bounces, :blocks, :spam_reports, :invalid_emails], @captured_remove_lists
  end
end
