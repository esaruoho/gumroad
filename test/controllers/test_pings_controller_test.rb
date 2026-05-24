# frozen_string_literal: true

require "test_helper"

class TestPingsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @seller = users(:named_seller)
    @seller.save! if @seller.external_id.blank?
    sign_in @seller
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "POST create returns error JSON when the URL is malformed" do
    post :create, params: { url: "not a url" }
    assert_response :success
    body = response.parsed_body
    assert_equal false, body["success"]
    assert_equal "That URL seems to be invalid.", body["error_message"]
  end

  test "POST create with no sales returns the no-sales message" do
    @seller.stubs(:send_test_ping).returns(false) if @seller.respond_to?(:stubs)
    User.define_method(:send_test_ping) { |_url| false }
    begin
      post :create, params: { url: "https://example.com/webhook" }
      assert_response :success
      body = response.parsed_body
      assert_equal true, body["success"]
      assert_match(/no sales/i, body["message"])
    ensure
      User.remove_method(:send_test_ping)
    end
  end

  test "POST create with sales returns the sent message" do
    User.define_method(:send_test_ping) { |_url| true }
    begin
      post :create, params: { url: "https://example.com/webhook" }
      assert_response :success
      body = response.parsed_body
      assert_equal true, body["success"]
      assert_match(/has been sent/, body["message"])
    ensure
      User.remove_method(:send_test_ping)
    end
  end

  test "POST create requires authentication" do
    sign_out @seller
    post :create, params: { url: "https://example.com" }
    assert_includes [302, 401, 403], @response.status
  end
end
