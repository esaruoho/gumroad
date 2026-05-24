# frozen_string_literal: true

require "test_helper"

class ProductReviewVideoTest < ActiveSupport::TestCase
  test "approval status transitions mark other videos of the same status as deleted" do
    product_review = product_reviews(:another_seller_product_review)
    pending_video = product_review_videos(:prvt_pending_video)
    approved_video = product_review_videos(:prvt_approved_video)
    rejected_video = product_review_videos(:prvt_rejected_video)

    new_video = ProductReviewVideo.new(product_review: product_review)
    new_video.video_file = VideoFile.new(
      record: new_video,
      user: users(:purchaser),
      url: "#{S3_BASE_URL}specs/prvt-new.mp4",
      filetype: "mp4",
    )
    new_video.save!

    assert_not pending_video.reload.deleted?
    new_video.pending_review!
    assert pending_video.reload.deleted?

    assert_not approved_video.reload.deleted?
    new_video.approved!
    assert approved_video.reload.deleted?

    assert_not rejected_video.reload.deleted?
    new_video.rejected!
    assert rejected_video.reload.deleted?
  end
end
