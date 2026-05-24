# frozen_string_literal: true

require "test_helper"

class ProductReviewVideos::StreamingUrlsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @prv = product_review_videos(:named_seller_product_review_video)
    @video_file = video_files(:named_seller_product_review_video_file)
    @product_review = @prv.product_review
    @purchase = @product_review.purchase
    @seller = @purchase.seller
    @purchaser = @purchase.purchaser

    # signed_download_url calls into S3 — stub at instance level via class override.
    @orig_signed_url = VideoFile.instance_method(:signed_download_url) if VideoFile.method_defined?(:signed_download_url)
    VideoFile.define_method(:signed_download_url) { "https://example.com/signed-video.mp4" }
  end

  teardown do
    VideoFile.remove_method(:signed_download_url) if VideoFile.instance_methods(false).include?(:signed_download_url)
    VideoFile.define_method(:signed_download_url, @orig_signed_url) if @orig_signed_url
  end

  test "returns streaming URLs when video is approved" do
    @prv.approved!
    travel_to Time.current do
      get :index, params: { product_review_video_id: @prv.external_id }, format: :json
    end
    assert_response :ok
    body = JSON.parse(@response.body)
    urls = body["streaming_urls"]
    assert_equal 2, urls.length
    assert_match %r{/product_review_videos/.+/stream\.smil$}, urls.first
    assert_equal "https://example.com/signed-video.mp4", urls.last
  end

  test "returns unauthorized when not approved and user not logged in" do
    @prv.pending_review!
    get :index, params: { product_review_video_id: @prv.external_id }, format: :json
    assert_response :unauthorized
  end

  test "succeeds when valid purchase_email_digest is provided" do
    @prv.pending_review!
    get :index, params: {
      product_review_video_id: @prv.external_id,
      purchase_email_digest: @purchase.email_digest
    }, format: :json
    assert_response :ok
  end

  test "succeeds when seller is signed in" do
    @prv.pending_review!
    sign_in @seller
    get :index, params: { product_review_video_id: @prv.external_id }, format: :json
    assert_response :ok
  end

  test "succeeds when purchaser is signed in" do
    @prv.pending_review!
    sign_in @purchaser
    get :index, params: { product_review_video_id: @prv.external_id }, format: :json
    assert_response :ok
  end

  test "raises RecordNotFound for nonexistent video" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get :index, params: { product_review_video_id: "nonexistent_id" }, format: :json
    end
  end
end
