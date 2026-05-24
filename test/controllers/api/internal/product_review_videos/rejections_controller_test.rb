# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class Api::Internal::ProductReviewVideos::RejectionsControllerTest < ActionController::TestCase
  tests Api::Internal::ProductReviewVideos::RejectionsController
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @admin = users(:admin_for_named_seller)
    @video = product_review_videos(:named_seller_product_review_video)
    @video.update!(approval_status: :pending_review)
  end

  teardown { restore_protect_against_forgery! }

  test "requires authentication" do
    boot_controller_test!
    post :create, params: { product_review_video_id: @video.external_id }, format: :json
    assert_includes [401, 404], @response.status
  end

  test "rejects the video when found" do
    sign_in_as_seller(@admin, @seller)
    post :create, params: { product_review_video_id: @video.external_id }, format: :json
    assert_response :ok
    assert_equal "rejected", @video.reload.approval_status
  end

  test "raises not found for non-existent product review video" do
    sign_in_as_seller(@admin, @seller)
    assert_raises(ActiveRecord::RecordNotFound) do
      post :create, params: { product_review_video_id: "non-existent-id" }, format: :json
    end
  end

  test "raises not found when the product review video has been soft-deleted" do
    sign_in_as_seller(@admin, @seller)
    @video.mark_deleted!
    assert_raises(ActiveRecord::RecordNotFound) do
      post :create, params: { product_review_video_id: @video.external_id }, format: :json
    end
    refute @video.reload.rejected?
  end

  test "returns unauthorized when the user does not have permission" do
    other = users(:purchaser)
    sign_in_as_seller(other, other)
    post :create, params: { product_review_video_id: @video.external_id }, format: :json
    assert_response :unauthorized
    refute @video.reload.rejected?
  end
end
