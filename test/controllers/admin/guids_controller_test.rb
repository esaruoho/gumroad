# frozen_string_literal: true

require "test_helper"

class Admin::GuidsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin_user = users(:admin_user)
    @user1 = users(:named_seller)
    @user2 = users(:another_seller)
    @user3 = users(:analytics_seller)
    @browser_guid = SecureRandom.uuid
    Event.create!(user_id: @user1.id, browser_guid: @browser_guid, event_name: "view")
    Event.create!(user_id: @user2.id, browser_guid: @browser_guid, event_name: "view")
    Event.create!(user_id: @user3.id, browser_guid: @browser_guid, event_name: "view")
    sign_in @admin_user
    @request.headers["X-Inertia"] = "true"
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::GuidsController.ancestors, Admin::BaseController
  end

  test "GET show returns successful response with Inertia page data" do
    get :show, params: { id: @browser_guid }
    assert_response :success
    assert_equal "Admin/Compliance/Guids/Show", JSON.parse(@response.body)["component"]
  end

  test "GET show returns unique users for the supplied browser GUID" do
    get :show, params: { id: @browser_guid }
    assert_response :success
    assert_equal [@user1, @user2, @user3].map(&:id).sort, assigns(:users).to_a.map(&:id).sort
  end

  test "GET show returns JSON response when requested" do
    get :show, params: { id: @browser_guid }, format: :json
    assert_response :success
    assert_match %r{application/json}, response.content_type
    body = response.parsed_body
    assert body["users"].present?
    assert_equal [@user1.external_id, @user2.external_id, @user3.external_id].sort, body["users"].map { |u| u["id"] }.sort
    assert body["pagination"].present?
  end

  test "GET show returns an empty array when no users are found for the GUID" do
    get :show, params: { id: SecureRandom.uuid }
    assert_response :success
    assert_empty assigns(:users).to_a
  end

  test "GET show returns only users with events for the specific GUID" do
    other_user = users(:purchaser)
    other_guid = SecureRandom.uuid
    Event.create!(user_id: other_user.id, browser_guid: other_guid, event_name: "view")

    get :show, params: { id: @browser_guid }
    assert_response :success
    ids = assigns(:users).to_a.map(&:id)
    assert_equal [@user1, @user2, @user3].map(&:id).sort, ids.sort
    assert_not_includes ids, other_user.id
  end

  test "GET show paginates results" do
    get :show, params: { id: @browser_guid, page: 1 }, format: :json
    assert_response :success
    assert_match %r{application/json}, response.content_type
    body = response.parsed_body
    assert body["users"].present?
    assert_equal [@user1.external_id, @user2.external_id, @user3.external_id].sort, body["users"].map { |u| u["id"] }.sort
    assert body["pagination"].present?
  end
end
