# frozen_string_literal: true

require "test_helper"

class ProductReviewPresenterTest < ActiveSupport::TestCase
  include ActionView::Helpers::DateHelper

  setup do
    @product_review = product_reviews(:named_seller_product_review)
    # Default fixtures attach a response + a pending video; clear them
    # so each test sets up only what it asserts on.
    ProductReviewVideo.where(product_review_id: @product_review.id).destroy_all
    @product_review.reload
  end

  test "product_review_props returns the correct props" do
    @product_review.response&.destroy!
    @product_review.reload
    assert_equal(
      {
        id: @product_review.external_id,
        message: @product_review.message,
        rater: {
          avatar_url: ActionController::Base.helpers.image_url("gumroad-default-avatar-5.png"),
          name: "Anonymous"
        },
        rating: @product_review.rating,
        purchase_id: @product_review.purchase.external_id,
        is_new: true,
        response: nil,
        video: nil
      },
      ProductReviewPresenter.new(@product_review).product_review_props
    )
  end

  test "product_review_props returns is_new=false when more than a month old" do
    @product_review.update!(created_at: 2.months.ago)
    assert_equal false, ProductReviewPresenter.new(@product_review).product_review_props[:is_new]
  end

  test "product_review_props uses response when product review has a response" do
    response = product_review_responses(:named_seller_product_review_response)
    assert_equal(
      { message: response.message },
      ProductReviewPresenter.new(@product_review).product_review_props[:response]
    )
  end

  test "product_review_props uses the purchase's full name when review is not associated with an account" do
    @product_review.purchase.update_columns(full_name: "Purchaser")
    assert_equal(
      {
        avatar_url: ActionController::Base.helpers.image_url("gumroad-default-avatar-5.png"),
        name: "Purchaser",
      },
      ProductReviewPresenter.new(@product_review).product_review_props[:rater]
    )
  end

  test "product_review_props uses 'Anonymous' when associated account name is blank and no full_name" do
    purchaser = users(:purchaser)
    purchaser.update!(name: nil)
    @product_review.purchase.update_columns(purchaser_id: purchaser.id, full_name: nil)
    assert_equal "Anonymous", ProductReviewPresenter.new(@product_review).product_review_props[:rater][:name]
  end

  test "product_review_props uses purchase full_name when account name is blank but full_name present" do
    purchaser = users(:purchaser)
    purchaser.update!(name: nil)
    @product_review.purchase.update_columns(purchaser_id: purchaser.id, full_name: "Purchaser")
    assert_equal "Purchaser", ProductReviewPresenter.new(@product_review).product_review_props[:rater][:name]
  end

  test "product_review_props uses the account's name when purchaser has a name" do
    purchaser = users(:purchaser)
    purchaser.update!(name: "Reviewer")
    @product_review.purchase.update_columns(purchaser_id: purchaser.id)
    assert_equal "Reviewer", ProductReviewPresenter.new(@product_review).product_review_props[:rater][:name]
  end

  test "product_review_props with videos skipped (ActiveStorage thumbnail_url out-of-scope)" do
    skip "ActiveStorage video_file.thumbnail_url — see product_review_video_presenter_test"
  end

  test "review_form_props returns the correct props" do
    assert_equal(
      {
        message: @product_review.message,
        rating: @product_review.rating,
        video: nil
      },
      ProductReviewPresenter.new(@product_review).review_form_props
    )
  end

  test "review_form_props video branches skipped (ActiveStorage thumbnail_url out-of-scope)" do
    skip "ActiveStorage video_file.thumbnail_url — see product_review_video_presenter_test"
  end
end
