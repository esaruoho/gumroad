# frozen_string_literal: true

require "test_helper"

class ProductReviewVideoPolicyTest < ActiveSupport::TestCase
  APPROVE_ACTIONS = %i[approve? reject?].freeze

  # SellerContext varies per spec context — sometimes seller is named_seller,
  # sometimes it's the purchaser themselves (their own one-person team).
  def policy_for(user_fixture, seller_fixture, record)
    context = SellerContext.new(user: users(user_fixture), seller: users(seller_fixture))
    ProductReviewVideoPolicy.new(context, record)
  end

  def assert_permits(user_fixture, seller_fixture, record, *actions)
    actions.each do |action|
      assert policy_for(user_fixture, seller_fixture, record).public_send(action),
             "expected ProductReviewVideoPolicy##{action} to permit #{user_fixture} (seller=#{seller_fixture})"
    end
  end

  def refute_permits(user_fixture, seller_fixture, record, *actions)
    actions.each do |action|
      refute policy_for(user_fixture, seller_fixture, record).public_send(action),
             "expected ProductReviewVideoPolicy##{action} to deny #{user_fixture} (seller=#{seller_fixture})"
    end
  end

  # ---- approve? / reject? : on seller's own product review video ----
  test "owner can approve/reject seller's product review video" do
    assert_permits :named_seller, :named_seller, product_review_videos(:named_seller_product_review_video), *APPROVE_ACTIONS
  end

  test "admin can approve/reject seller's product review video" do
    assert_permits :admin_for_named_seller, :named_seller, product_review_videos(:named_seller_product_review_video), *APPROVE_ACTIONS
  end

  test "support can approve/reject seller's product review video" do
    assert_permits :support_for_named_seller, :named_seller, product_review_videos(:named_seller_product_review_video), *APPROVE_ACTIONS
  end

  test "accountant cannot approve/reject seller's product review video" do
    refute_permits :accountant_for_named_seller, :named_seller, product_review_videos(:named_seller_product_review_video), *APPROVE_ACTIONS
  end

  test "marketing cannot approve/reject seller's product review video" do
    refute_permits :marketing_for_named_seller, :named_seller, product_review_videos(:named_seller_product_review_video), *APPROVE_ACTIONS
  end

  # ---- approve? / reject? : on another seller's video — all roles denied ----
  test "owner cannot approve/reject another seller's product review video" do
    refute_permits :named_seller, :named_seller, product_review_videos(:another_seller_product_review_video), *APPROVE_ACTIONS
  end

  test "admin cannot approve/reject another seller's product review video" do
    refute_permits :admin_for_named_seller, :named_seller, product_review_videos(:another_seller_product_review_video), *APPROVE_ACTIONS
  end

  test "support cannot approve/reject another seller's product review video" do
    refute_permits :support_for_named_seller, :named_seller, product_review_videos(:another_seller_product_review_video), *APPROVE_ACTIONS
  end

  test "accountant cannot approve/reject another seller's product review video" do
    refute_permits :accountant_for_named_seller, :named_seller, product_review_videos(:another_seller_product_review_video), *APPROVE_ACTIONS
  end

  test "marketing cannot approve/reject another seller's product review video" do
    refute_permits :marketing_for_named_seller, :named_seller, product_review_videos(:another_seller_product_review_video), *APPROVE_ACTIONS
  end

  # ---- stream? : approved video is publicly streamable ----
  test "any seller can stream an approved video regardless of ownership" do
    video = product_review_videos(:another_seller_product_review_video)
    video.update_column(:approval_status, "approved")
    assert_permits :named_seller, :named_seller, video, :stream?
  end

  test "seller cannot stream another seller's unapproved video" do
    video = product_review_videos(:another_seller_product_review_video)
    video.update_column(:approval_status, "pending_review")
    refute_permits :named_seller, :named_seller, video, :stream?
  end

  # ---- stream? : seller side — all 5 roles can stream their own pending video ----
  test "owner can stream seller's own pending video" do
    assert_permits :named_seller, :named_seller, product_review_videos(:named_seller_product_review_video), :stream?
  end

  test "admin can stream seller's own pending video" do
    assert_permits :admin_for_named_seller, :named_seller, product_review_videos(:named_seller_product_review_video), :stream?
  end

  test "support can stream seller's own pending video" do
    assert_permits :support_for_named_seller, :named_seller, product_review_videos(:named_seller_product_review_video), :stream?
  end

  test "accountant can stream seller's own pending video" do
    assert_permits :accountant_for_named_seller, :named_seller, product_review_videos(:named_seller_product_review_video), :stream?
  end

  test "marketing can stream seller's own pending video" do
    assert_permits :marketing_for_named_seller, :named_seller, product_review_videos(:named_seller_product_review_video), :stream?
  end

  # ---- stream? : purchaser context — purchaser can stream their review's video ----
  test "purchaser can stream their own pending review video" do
    assert_permits :purchaser, :purchaser, product_review_videos(:named_seller_product_review_video), :stream?
  end

  test "named_seller (acting as purchaser-context) cannot stream another user's pending review video" do
    # context_seller = purchaser, user = named_seller — neither owner nor purchaser path matches.
    refute_permits :named_seller, :purchaser, product_review_videos(:named_seller_product_review_video), :stream?
  end
end
