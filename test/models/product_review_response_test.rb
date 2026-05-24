# frozen_string_literal: true

require "test_helper"

class ProductReviewResponseTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "validates presence of message" do
    response = ProductReviewResponse.new(
      product_review: product_reviews(:named_seller_product_review),
      user: users(:named_seller),
    )
    assert_not response.valid?
    assert_includes response.errors[:message], "can't be blank"
  end

  test "sends an email to the reviewer after creation" do
    review = product_reviews(:named_seller_product_review)
    response = ProductReviewResponse.new(
      product_review: review,
      user: users(:named_seller),
      message: "Thanks for the review!",
    )

    assert_enqueued_email_with(CustomerMailer, :review_response, args: [response]) do
      response.save!
    end

    assert_no_enqueued_emails do
      response.update!(message: "Updated message")
    end
  end
end
