# frozen_string_literal: true

require "test_helper"

class ProductReview::UpdateServiceTest < ActiveSupport::TestCase
  setup do
    @product_review = product_reviews(:named_seller_product_review)
    @product_review.update_columns(rating: 3, message: "Original message")
  end

  test "#update returns the product review" do
    returned_product_review = ProductReview::UpdateService
      .new(@product_review, rating: 5, message: "Updated message")
      .update

    assert_equal @product_review, returned_product_review
  end

  test "#update updates the product review with the new rating and message" do
    ProductReview::UpdateService.new(@product_review, rating: 5, message: "Updated message").update

    assert_equal 5, @product_review.rating
    assert_equal "Updated message", @product_review.message
  end

  test "#update creates a new video and deletes existing pending-review videos" do
    existing_pending_video = product_review_videos(:named_seller_product_review_video)
    blob = active_storage_blob
    video_url = "#{S3_BASE_URL}video.mp4"

    assert_difference -> { @product_review.videos.count }, 1 do
      ProductReview::UpdateService.new(
        @product_review,
        rating: 4,
        message: "With video",
        video_options: {
          create: { url: video_url, thumbnail_signed_id: blob.signed_id },
        }
      ).update
    end

    assert_equal true, existing_pending_video.reload.deleted?
    new_video = @product_review.videos.where.not(id: existing_pending_video.id).last
    assert_equal "pending_review", new_video.approval_status
    assert_equal video_url, new_video.video_file.url
    assert_equal blob.signed_id, new_video.video_file.thumbnail.signed_id
  end

  test "#update marks a video as deleted when destroy option is provided" do
    video = product_review_videos(:named_seller_product_review_video)

    ProductReview::UpdateService.new(
      @product_review,
      rating: 4,
      message: "Remove video",
      video_options: { destroy: { id: video.external_id } }
    ).update

    assert_equal true, video.reload.deleted?
  end

  private
    def active_storage_blob
      ActiveStorage::Blob.create!(
        key: "product-review-update-service/#{SecureRandom.hex}",
        filename: "test-small.jpg",
        content_type: "image/jpeg",
        metadata: { identified: true },
        service_name: "test",
        byte_size: 100,
        checksum: Digest::MD5.base64digest("thumbnail")
      )
    end
end
