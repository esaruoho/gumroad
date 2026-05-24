# frozen_string_literal: true

require "test_helper"

class ProductReviewPresenterTest < ActiveSupport::TestCase
  setup do
    # named_seller_product_review has a pending video (named_seller_product_review_video).
    # We use it as-is and assert on the realistic state.
    @product_review = product_reviews(:named_seller_product_review)
    @purchase = @product_review.purchase
  end

  test "product_review_props returns Anonymous when purchaser/full_name blank" do
    @purchase.purchaser.update_columns(name: nil)
    @purchase.update_columns(full_name: nil)
    @product_review.reload

    props = ProductReviewPresenter.new(@product_review).product_review_props
    assert_equal @product_review.external_id, props[:id]
    assert_equal @product_review.message, props[:message]
    assert_equal @product_review.rating, props[:rating]
    assert_equal @purchase.external_id, props[:purchase_id]
    assert_equal true, props[:is_new]
    assert_equal({ message: "Thanks!" }, props[:response]) # fixture-loaded response
    assert_nil props[:video] # pending video → approved_video is nil
    assert_equal "Anonymous", props[:rater][:name]
  end

  test "product_review_props is_new false when older than a month" do
    @product_review.update_columns(created_at: 2.months.ago)
    refute ProductReviewPresenter.new(@product_review.reload).product_review_props[:is_new]
  end

  test "product_review_props uses purchase full_name when purchaser has no name" do
    @purchase.purchaser.update_columns(name: nil)
    @purchase.update_columns(full_name: "Purchaser")
    @product_review.reload

    rater = ProductReviewPresenter.new(@product_review).product_review_props[:rater]
    assert_equal "Purchaser", rater[:name]
  end

  test "product_review_props uses purchaser name when present" do
    @purchase.purchaser.update_columns(name: "Reviewer")
    @product_review.reload

    rater = ProductReviewPresenter.new(@product_review).product_review_props[:rater]
    assert_equal "Reviewer", rater[:name]
  end

  test "product_review_props includes response when present" do
    response = product_review_responses(:named_seller_product_review_response)

    props = ProductReviewPresenter.new(@product_review.reload).product_review_props
    assert_equal({ message: response.message }, props[:response])
  end

  test "product_review_props returns approved video props" do
    video = @product_review.videos.first
    video.update_columns(approval_status: "approved")
    @product_review.reload

    video_props = ProductReviewPresenter.new(@product_review).product_review_props[:video]
    assert_equal video.external_id, video_props[:id]
    assert video_props.key?(:thumbnail_url)
  end

  test "review_form_props returns props including pending video as editable" do
    props = ProductReviewPresenter.new(@product_review).review_form_props
    assert_equal @product_review.rating, props[:rating]
    assert_equal @product_review.message, props[:message]
    assert_equal @product_review.videos.first.external_id, props[:video][:id]
  end

  test "review_form_props excludes rejected video" do
    @product_review.videos.first.update_columns(approval_status: "rejected")
    @product_review.reload
    assert_nil ProductReviewPresenter.new(@product_review).review_form_props[:video]
  end
end
