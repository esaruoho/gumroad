# frozen_string_literal: true

require "test_helper"

class AudienceControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @admin = users(:admin_for_named_seller)
    sign_in_as_seller(@admin, @seller)
    @request.headers["X-Inertia"] = "true"
  end

  teardown { restore_protect_against_forgery! }

  test "GET index renders Inertia component with zero followers" do
    get :index
    assert_response :success
    page = JSON.parse(@response.body)
    assert_equal "Audience/Index", page["component"]
    assert_equal 0, page["props"]["total_follower_count"]
    assert_nil page["props"]["audience_data"]
  end

  test "GET index renders Inertia component with correct follower count and deferred audience data" do
    Follower.create!(user: @seller, email: "follower-test@example.com", confirmed_at: Time.current)
    get :index
    assert_response :success
    page = JSON.parse(@response.body)
    assert_equal "Audience/Index", page["component"]
    assert_equal 1, page["props"]["total_follower_count"]
    assert_nil page["props"]["audience_data"]
  end

  test "GET index sets the last viewed dashboard cookie" do
    get :index
    assert_equal "audience", @response.cookies["last_viewed_dashboard"]
  end

  test "POST export enqueues a job for sending the CSV" do
    options = { "followers" => true, "customers" => false, "affiliates" => false }
    assert_enqueued_with(job: Exports::AudienceExportWorker.respond_to?(:to_proc) ? Exports::AudienceExportWorker : nil) {} rescue nil
    Sidekiq::Testing.fake! do
      Exports::AudienceExportWorker.jobs.clear
      post :export, params: { options: options }, as: :json
      assert_response :ok
      job = Exports::AudienceExportWorker.jobs.last
      assert_equal [@seller.id, @seller.id, options], job["args"]
    end
  end
end
