# frozen_string_literal: true

require "test_helper"

# The controller class is `ProductFilesUtilityController` (no `Products::` namespace),
# but the original spec lived under `spec/controllers/products/` so we keep the test
# file path stable and use `tests` to point at the real controller class.
class Products::ProductFilesUtilityControllerTest < ActionController::TestCase
  tests ProductFilesUtilityController
  include Devise::Test::ControllerHelpers

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @seller = users(:named_seller)
    @seller.save(validate: false) if @seller.external_id.blank?
    sign_in @seller
    @request.cookie_jar.encrypted[:current_seller_id] = @seller.id
  end

  test "GET external_link_title returns success false when fetch raises" do
    SsrfFilter.stub(:get, ->(_) { raise StandardError, "boom" }) do
      get :external_link_title, params: { url: "https://example.com" }
    end
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal false, body["success"]
  end

  test "GET external_link_title parses page title from successful response" do
    fake = Object.new
    fake.define_singleton_method(:body) { "<html><head><title>Hello</title></head></html>" }
    SsrfFilter.stub(:get, ->(_) { fake }) do
      get :external_link_title, params: { url: "https://example.com" }
    end
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal true, body["success"]
    assert_equal "Hello", body["title"]
  end

  test "GET external_link_title defaults to 'Untitled' when no <title>" do
    fake = Object.new
    fake.define_singleton_method(:body) { "<html><head></head></html>" }
    SsrfFilter.stub(:get, ->(_) { fake }) do
      get :external_link_title, params: { url: "https://example.com" }
    end
    body = JSON.parse(@response.body)
    assert_equal "Untitled", body["title"]
  end

  test "GET external_link_title redirects to login when not signed in" do
    sign_out @seller
    get :external_link_title, params: { url: "https://example.com" }
    assert_response :redirect
  end
end
