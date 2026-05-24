# frozen_string_literal: true

require "test_helper"

class ProductReviewVideoPresenterTest < ActiveSupport::TestCase
  setup do
    @video = product_review_videos(:prvt_approved_video)
    @seller = @video.product_review.link.user
    @another_seller = users(:basic_user)
  end

  test "props returns id, approval_status, and thumbnail_url with permissions" do
    pundit_user = SellerContext.new(user: @seller, seller: @seller)
    props = ProductReviewVideoPresenter.new(@video).props(pundit_user:)

    assert_equal @video.external_id, props[:id]
    assert_equal @video.approval_status, props[:approval_status]
    assert props.key?(:thumbnail_url)
    assert_equal true, props[:can_approve]
    assert_equal true, props[:can_reject]
  end

  test "props returns can_approve/can_reject false for unrelated seller" do
    pundit_user = SellerContext.new(user: @another_seller, seller: @another_seller)
    props = ProductReviewVideoPresenter.new(@video).props(pundit_user:)

    assert_equal false, props[:can_approve]
    assert_equal false, props[:can_reject]
  end
end
