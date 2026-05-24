# frozen_string_literal: true

require "test_helper"

class Admin::CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin_user = users(:admin_user)
    @user = users(:named_seller)
    sign_in @admin_user
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
    @comment_attrs = {
      content: "comment content",
      comment_type: "comment",
      commentable_type: "User",
      commentable_id: @user.id
    }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::CommentsController.ancestors, Admin::BaseController
  end

  test "POST create creates the comment with valid params" do
    assert_difference -> { Comment.count }, 1 do
      post :create, params: { comment: @comment_attrs }
    end
    assert_equal @comment_attrs[:content], Comment.last.content
  end

  test "POST create does not create comment with invalid params" do
    @comment_attrs.delete(:content)
    assert_raises(ActiveRecord::RecordInvalid) do
      post :create, params: { comment: @comment_attrs }
    end
  end
end
