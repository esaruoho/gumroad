# frozen_string_literal: true

require "test_helper"

class PaginatedCommentsPresenterTest < ActiveSupport::TestCase
  setup do
    @product = links(:named_seller_product)
    @post = installments(:pcp_post)
    @logged_in_user = users(:basic_user)
    @pundit_user = SellerContext.new(user: @logged_in_user, seller: @logged_in_user)
    @comment1 = comments(:pcp_comment1)
    @comment2 = comments(:pcp_comment2)

    # Stub class constant for the duration of the test.
    @original_per_page = PaginatedCommentsPresenter::COMMENTS_PER_PAGE
    PaginatedCommentsPresenter.send(:remove_const, :COMMENTS_PER_PAGE)
    PaginatedCommentsPresenter.const_set(:COMMENTS_PER_PAGE, 1)
  end

  teardown do
    PaginatedCommentsPresenter.send(:remove_const, :COMMENTS_PER_PAGE)
    PaginatedCommentsPresenter.const_set(:COMMENTS_PER_PAGE, @original_per_page)
  end

  def build_presenter(options: {}, purchase: nil)
    PaginatedCommentsPresenter.new(pundit_user: @pundit_user, commentable: @post, purchase:, options:)
  end

  test "returns paginated comments for the first page when page option not specified" do
    result = build_presenter.result
    assert_equal 1, result[:comments].length
    assert_equal @comment1.external_id, result[:comments].first[:id]
    assert_equal({ count: 2, items: 1, pages: 2, page: 1, next: 2, prev: nil, last: 2 }, result[:pagination])
  end

  test "returns paginated comments for the specified page" do
    result = build_presenter(options: { page: 2 }).result
    assert_equal 1, result[:comments].length
    assert_equal @comment2.external_id, result[:comments].first[:id]
    assert_equal({ count: 2, items: 1, pages: 2, page: 2, next: nil, prev: 1, last: 2 }, result[:pagination])
  end

  test "raises Pagy::OverflowError when page is overflowed" do
    assert_raises(Pagy::OverflowError) do
      build_presenter(options: { page: 3 }).result
    end
  end

  test "returns count of all root comments and descendants regardless of page" do
    reply1_to_comment1 = Comment.create!(parent: @comment1, commentable: @post, author: @logged_in_user, content: "r1c1", comment_type: Comment::COMMENT_TYPE_USER_SUBMITTED)
    reply1_to_comment2 = Comment.create!(parent: @comment2, commentable: @post, author: @logged_in_user, content: "r1c2", comment_type: Comment::COMMENT_TYPE_USER_SUBMITTED)
    reply_at_depth_2 = Comment.create!(parent: reply1_to_comment2, commentable: @post, author: @logged_in_user, content: "d2", comment_type: Comment::COMMENT_TYPE_USER_SUBMITTED)
    reply_at_depth_3 = Comment.create!(parent: reply_at_depth_2, commentable: @post, author: @logged_in_user, content: "d3", comment_type: Comment::COMMENT_TYPE_USER_SUBMITTED)
    Comment.create!(parent: reply_at_depth_3, commentable: @post, author: @logged_in_user, content: "d4", comment_type: Comment::COMMENT_TYPE_USER_SUBMITTED)

    result = build_presenter(options: { page: 2 }).result
    assert_equal 5, result[:comments].length
    assert_equal 7, result[:count]
  end

  test "returns paginated root comments for page 1 along with their descendants" do
    reply1_to_comment1 = Comment.create!(parent: @comment1, commentable: @post, author: @logged_in_user, content: "r1c1", comment_type: Comment::COMMENT_TYPE_USER_SUBMITTED)
    Comment.create!(parent: @comment2, commentable: @post, author: @logged_in_user, content: "r1c2", comment_type: Comment::COMMENT_TYPE_USER_SUBMITTED)

    result = build_presenter(options: { page: 1 }).result
    assert_equal 2, result[:comments].length
    assert_equal [@comment1.external_id, reply1_to_comment1.external_id].sort,
                 result[:comments].pluck(:id).sort
  end

  test "returns paginated root comments for page 2 along with their descendants" do
    Comment.create!(parent: @comment1, commentable: @post, author: @logged_in_user, content: "r1c1", comment_type: Comment::COMMENT_TYPE_USER_SUBMITTED)
    reply1_to_comment2 = Comment.create!(parent: @comment2, commentable: @post, author: @logged_in_user, content: "r1c2", comment_type: Comment::COMMENT_TYPE_USER_SUBMITTED)
    reply_at_depth_2 = Comment.create!(parent: reply1_to_comment2, commentable: @post, author: @logged_in_user, content: "d2", comment_type: Comment::COMMENT_TYPE_USER_SUBMITTED)
    reply_at_depth_3 = Comment.create!(parent: reply_at_depth_2, commentable: @post, author: @logged_in_user, content: "d3", comment_type: Comment::COMMENT_TYPE_USER_SUBMITTED)
    reply_at_depth_4 = Comment.create!(parent: reply_at_depth_3, commentable: @post, author: @logged_in_user, content: "d4", comment_type: Comment::COMMENT_TYPE_USER_SUBMITTED)

    result = build_presenter(options: { page: 2 }).result
    assert_equal 5, result[:comments].length
    assert_equal [
      @comment2.external_id,
      reply1_to_comment2.external_id,
      reply_at_depth_2.external_id,
      reply_at_depth_3.external_id,
      reply_at_depth_4.external_id
    ].sort, result[:comments].pluck(:id).sort
  end
end
