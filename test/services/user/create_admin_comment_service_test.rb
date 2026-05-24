# frozen_string_literal: true

require "test_helper"

class User::CreateAdminCommentServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:basic_user)
    @admin_user = users(:admin_user)
  end

  test "creates a comment with COMMENT_TYPE_NOTE attributed to GUMROAD_ADMIN_ID" do
    with_const(:GUMROAD_ADMIN_ID, @admin_user.id) do
      comment = User::CreateAdminCommentService.new(user: @user, content: "Note from support", idempotency_key: "key-1").perform

      assert_predicate comment, :persisted?
      assert_equal "Note from support", comment.content
      assert_equal Comment::COMMENT_TYPE_NOTE, comment.comment_type
      assert_equal @admin_user.id, comment.author_id
      assert_equal "key-1", comment.idempotency_key
      assert_equal @user, comment.commentable
    end
  end

  test "creates a comment attributed to the supplied author" do
    actor = users(:admin_user)
    with_const(:GUMROAD_ADMIN_ID, @admin_user.id) do
      comment = User::CreateAdminCommentService.new(user: @user, content: "Note from support", idempotency_key: "key-2", author_id: actor.id).perform
      assert_predicate comment, :persisted?
      assert_equal actor.id, comment.author_id
    end
  end

  test "returns the existing comment when called twice with the same idempotency key and matching content" do
    with_const(:GUMROAD_ADMIN_ID, @admin_user.id) do
      first = User::CreateAdminCommentService.new(user: @user, content: "Same content", idempotency_key: "dup").perform
      second = User::CreateAdminCommentService.new(user: @user, content: "Same content", idempotency_key: "dup").perform

      assert_equal first.id, second.id
      assert_equal 1, @user.comments.where(idempotency_key: "dup").count
    end
  end

  test "raises IdempotencyConflictError when an existing key is reused with different content" do
    with_const(:GUMROAD_ADMIN_ID, @admin_user.id) do
      User::CreateAdminCommentService.new(user: @user, content: "Original", idempotency_key: "shared").perform

      assert_raises(User::CreateAdminCommentService::IdempotencyConflictError) do
        User::CreateAdminCommentService.new(user: @user, content: "Different", idempotency_key: "shared").perform
      end
    end
  end

  test "returns a comment with errors when validation fails" do
    with_const(:GUMROAD_ADMIN_ID, @admin_user.id) do
      invalid = User::CreateAdminCommentService.new(user: @user, content: "", idempotency_key: "invalid").perform
      refute_predicate invalid, :persisted?
      assert_predicate invalid.errors, :present?
    end
  end
end
