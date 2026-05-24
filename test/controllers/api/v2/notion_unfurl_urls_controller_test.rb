# frozen_string_literal: true

require "test_helper"

class Api::V2::NotionUnfurlUrlsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  setup do
    @seller = users(:named_seller) # username: "luke", external_id auto-assigned
    @seller.update!(username: "john") if @seller.username != "john"
    @product = links(:named_seller_product) # name: Named seller's product
    @product.update_columns(description: "<p>Lorem ipsum</p>")

    @app_owner = users(:basic_user)
    @token_owner = users(:purchaser)
    [@app_owner, @token_owner].each { |u| u.save! if u.external_id.blank? }

    @oauth_app = OauthApplication.create!(
      name: "Test App", redirect_uri: "https://example.com", owner: @app_owner, scopes: "unfurl"
    )
    @access_token = Doorkeeper::AccessToken.create!(
      application: @oauth_app, resource_owner_id: @token_owner.id, scopes: "unfurl"
    )
  end

  test "POST create unauthorized without token" do
    post :create
    assert_response :unauthorized
    body = response.parsed_body
    assert_equal 401, body["error"]["status"]
  end

  test "POST create with no uri param returns Product not found error" do
    @request.headers["Authorization"] = "Bearer #{@access_token.token}"
    post :create
    assert_response :not_found
    assert_equal({ "error" => { "status" => 404, "message" => "Product not found" } }, response.parsed_body)
  end

  test "POST create with invalid uri returns operations error" do
    @request.headers["Authorization"] = "Bearer #{@access_token.token}"
    post :create, params: { uri: "example.com" }
    assert_response :not_found
    body = response.parsed_body
    assert_equal "example.com", body["uri"]
    assert_equal "Product not found", body["operations"][0]["set"]["message"]
  end

  test "POST create with seller missing in uri returns operations error" do
    @request.headers["Authorization"] = "Bearer #{@access_token.token}"
    uri = "#{PROTOCOL}://someone-#{SecureRandom.hex(3)}.#{ROOT_DOMAIN}"
    post :create, params: { uri: uri }
    assert_response :not_found
    body = response.parsed_body
    assert_equal uri, body["uri"]
  end

  test "POST create with valid product uri returns the unfurl payload" do
    @request.headers["Authorization"] = "Bearer #{@access_token.token}"
    uri = "#{PROTOCOL}://john.#{ROOT_DOMAIN}/l/#{@product.unique_permalink}"
    post :create, params: { uri: "#{uri}?hello=test" }
    assert_response :ok
    body = response.parsed_body
    assert_equal "#{uri}?hello=test", body["uri"]
    attrs = body["operations"][0]["set"]
    ids = attrs.map { |a| a["id"] }
    assert_includes ids, "title"
    assert_includes ids, "creator_name"
    assert_includes ids, "price"
    assert_includes ids, "description"
  end

  test "DELETE destroy returns ok and empty body" do
    @request.headers["Authorization"] = "Bearer #{@access_token.token}"
    delete :destroy, params: { uri: "https://example.com" }
    assert_response :ok
    assert_equal "", response.body
  end
end
