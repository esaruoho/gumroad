# frozen_string_literal: true

require "test_helper"

class Admin::Purchases::CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include AdminCommentableAssertions

  setup do
    @admin_user = users(:admin_user)
    @admin_user.save! if @admin_user.external_id.blank?
    sign_in @admin_user
    @purchase = purchases(:named_seller_call_purchase)
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  def commentable_object
    @purchase
  end

  def route_params
    { purchase_external_id: @purchase.external_id }
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::Purchases::CommentsController.ancestors, Admin::BaseController
  end

  test "GET index returns all comments in descending order" do
    assert_admin_commentable_index_returns_comments_in_descending_order
  end

  test "GET index paginates comments correctly" do
    assert_admin_commentable_index_paginates
  end

  test "GET index returns empty array when there are no comments" do
    assert_admin_commentable_index_returns_empty_when_no_comments
  end

  test "POST create creates a new comment for the commentable" do
    assert_admin_commentable_create_creates_a_comment
  end

  test "POST create associates the comment with the current admin user" do
    assert_admin_commentable_create_associates_with_admin
  end

  test "POST create returns an error when content is missing" do
    assert_admin_commentable_create_error_when_blank
  end

  test "POST create creates a comment with note type when comment_type is not provided" do
    assert_admin_commentable_create_defaults_to_note
  end

  test "POST create returns an error when content is too long" do
    assert_admin_commentable_create_error_when_too_long
  end
end
