# frozen_string_literal: true

require "test_helper"

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  test "GET index returns 404 JSON when the post is missing" do
    get :index, params: { post_id: "missing-external-id" }
    assert_response :not_found
  end

  test "POST create returns 404 JSON when the post is missing" do
    post :create, params: { post_id: "missing-external-id", comment: { content: "hi" } }
    assert_response :not_found
  end

  test "PATCH update returns 404 JSON when the post is missing" do
    patch :update, params: { post_id: "missing-external-id", id: "nope", comment: { content: "x" } }
    assert_response :not_found
  end

  test "DELETE destroy returns 404 JSON when the post is missing" do
    delete :destroy, params: { post_id: "missing-external-id", id: "nope" }
    assert_response :not_found
  end
end
