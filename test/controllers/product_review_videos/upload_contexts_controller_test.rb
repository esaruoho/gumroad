# frozen_string_literal: true

require "test_helper"

class ProductReviewVideos::UploadContextsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @user = users(:named_seller)
  end

  test "GET show redirects to login when unauthenticated" do
    get :show
    assert_response :redirect
    assert_match login_url, response.location
  end

  test "GET show returns the upload context with correct values" do
    sign_in @user
    get :show

    assert_response :success
    assert_equal(
      {
        "aws_access_key_id" => AWS_ACCESS_KEY,
        "s3_url" => "#{AWS_S3_ENDPOINT}/#{S3_BUCKET}",
        "user_id" => @user.external_id,
      },
      response.parsed_body
    )
  end
end
