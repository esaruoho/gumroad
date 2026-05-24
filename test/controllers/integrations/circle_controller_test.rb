# frozen_string_literal: true

require "test_helper"

class Integrations::CircleControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @seller = users(:named_seller)
    @seller.save(validate: false) if @seller.external_id.blank?
    sign_in @seller
    @request.cookie_jar.encrypted[:current_seller_id] = @seller.id
  end

  test "GET communities returns success false when api_key is blank" do
    get :communities, params: { api_key: "" }
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal false, body["success"]
  end

  test "GET space_groups returns success false when community_id is blank" do
    get :space_groups, params: { api_key: "k" }
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal false, body["success"]
  end

  test "GET space_groups returns success false when api_key is blank" do
    get :space_groups, params: { community_id: "1" }
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal false, body["success"]
  end

  test "GET communities_and_space_groups returns success false when params blank" do
    get :communities_and_space_groups, params: { community_id: "" }
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal false, body["success"]
  end

  test "GET communities returns parsed payload on successful Circle response" do
    fake_response = Object.new
    fake_response.define_singleton_method(:success?) { true }
    fake_response.define_singleton_method(:parsed_response) { [{ "name" => "Community A", "id" => 1 }, { "name" => "Community B", "id" => 2 }] }

    fake_api = Object.new
    fake_api.define_singleton_method(:get_communities) { fake_response }

    orig_new = CircleApi.method(:new)
    CircleApi.define_singleton_method(:new) { |_| fake_api }

    begin
      get :communities, params: { api_key: "test-key" }
      assert_response :success
      body = JSON.parse(@response.body)
      assert_equal true, body["success"]
      assert_equal [{ "name" => "Community A", "id" => 1 }, { "name" => "Community B", "id" => 2 }], body["communities"]
    ensure
      CircleApi.define_singleton_method(:new, orig_new)
    end
  end
end
