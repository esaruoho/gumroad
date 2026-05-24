# frozen_string_literal: true

require "test_helper"

# Migrated from spec/policies/comment_context_policy_spec.rb (deleted in
# c9c93ee5). Replaces the 432-line factory-driven spec with explicit
# Minitest assertions backed by YAML fixtures + a few inline ActiveRecord
# rows for the policy-shaped objects the cases need.
class CommentContextPolicyTest < ActiveSupport::TestCase
  setup do
    @seller                 = users(:named_seller)
    @accountant_for_seller  = users(:accountant_for_named_seller)
    @admin_for_seller       = users(:admin_for_named_seller)
    @marketing_for_seller   = users(:marketing_for_named_seller)
    @support_for_seller     = users(:support_for_named_seller)
    @buyer                  = users(:basic_user)
    @another_seller         = users(:another_seller)
    @visitor                = users(:referrer_user)
    @comment_author         = users(:purchaser)
    @product                = links(:named_seller_product)
  end

  def commentable_product_post(seller: @seller, link: @product, published_at: 1.day.ago)
    Installment.create!(
      seller: seller,
      link: link,
      installment_type: Installment::PRODUCT_TYPE,
      name: "P", message: "Hi",
      published_at: published_at,
      flags: 128, # shown_on_profile
    )
  end

  def commentable_seller_post(seller: @seller, published_at: 1.day.ago)
    Installment.create!(
      seller: seller,
      installment_type: Installment::SELLER_TYPE,
      name: "S", message: "Hi",
      published_at: published_at,
      flags: 128,
    )
  end

  def successful_purchase(seller: @seller, link: @product, purchaser: nil, created_at: 1.second.ago)
    p = Purchase.new(
      seller: seller,
      link: link,
      purchaser: purchaser,
      email: purchaser&.email || "buyer-#{SecureRandom.hex(4)}@example.com",
      price_cents: 100,
      total_transaction_cents: 100,
      fee_cents: 0,
      displayed_price_cents: 100,
      displayed_price_currency_type: "usd",
      purchase_state: "successful",
      succeeded_at: created_at,
      created_at: created_at,
    )
    p.save!(validate: false)
    p
  end

  def comment_for(commentable, author: nil, purchase: nil)
    Comment.new(
      commentable: commentable,
      author: author,
      purchase: purchase,
      content: "hi",
      comment_type: Comment::COMMENT_TYPE_USER_SUBMITTED,
    )
  end

  def permits?(seller_context, comment_context, action)
    CommentContextPolicy.new(seller_context, comment_context).public_send(action)
  end

  # --- assigns accessors ----------------------------------------------------
  test "assigns accessors" do
    context = SellerContext.new(user: @admin_for_seller, seller: @seller)
    policy = CommentContextPolicy.new(context, :record)

    assert_equal @admin_for_seller, policy.user
    assert_equal @seller, policy.seller
    assert_equal :record, policy.record
  end

  # --- index? ---------------------------------------------------------------
  test "index? grants access to seller-side roles on their own post" do
    commentable = commentable_product_post
    cc = CommentContext.new(comment: nil, commentable: commentable, purchase: nil)

    [@seller, @admin_for_seller, @marketing_for_seller].each do |u|
      assert permits?(SellerContext.new(user: u, seller: @seller), cc, :index?),
             "expected #{u.email} to be permitted"
    end
  end

  test "index? denies non-admin/marketing seller-side roles via the role gate when seller != self" do
    commentable = commentable_product_post
    cc = CommentContext.new(comment: nil, commentable: commentable, purchase: nil)

    refute permits?(SellerContext.new(user: @accountant_for_seller, seller: @another_seller), cc, :index?)
    refute permits?(SellerContext.new(user: @support_for_seller, seller: @another_seller), cc, :index?)
  end

  test "index? denies a buyer without a matching purchase" do
    commentable = commentable_product_post
    cc = CommentContext.new(comment: nil, commentable: commentable, purchase: nil)

    refute permits?(SellerContext.new(user: @buyer, seller: @buyer), cc, :index?)
  end

  test "index? grants access to buyer when buyer has a matching purchase (via visible_posts_for)" do
    # purchase must be created before the post's published_at
    successful_purchase(purchaser: @buyer, created_at: 2.days.ago)
    commentable = commentable_product_post(published_at: 1.day.ago)
    cc = CommentContext.new(comment: nil, commentable: commentable, purchase: nil)

    assert permits?(SellerContext.new(user: @buyer, seller: @buyer), cc, :index?)
  end

  test "index? denies logged-out user on a non-public post" do
    commentable = commentable_product_post
    cc = CommentContext.new(comment: nil, commentable: commentable, purchase: nil)

    refute permits?(SellerContext.logged_out, cc, :index?)
  end

  test "index? grants logged-out user when post is public AUDIENCE type" do
    commentable = Installment.create!(
      seller: @seller,
      installment_type: Installment::AUDIENCE_TYPE,
      name: "A", message: "Hi",
      published_at: 1.day.ago,
      flags: 128, # shown_on_profile
    )
    cc = CommentContext.new(comment: nil, commentable: commentable, purchase: nil)

    assert permits?(SellerContext.logged_out, cc, :index?)
  end

  test "index? with purchase: grants when purchase matches a product post" do
    commentable = commentable_product_post
    purchase = successful_purchase
    cc = CommentContext.new(comment: nil, commentable: commentable, purchase: purchase)

    assert permits?(SellerContext.logged_out, cc, :index?)
  end

  test "index? with purchase: denies when purchase does not match a product post" do
    commentable = commentable_product_post
    other_product = links(:save_public_files_product)
    purchase = successful_purchase(link: other_product)
    cc = CommentContext.new(comment: nil, commentable: commentable, purchase: purchase)

    refute permits?(SellerContext.logged_out, cc, :index?)
  end

  test "index? with purchase: grants when purchase matches seller post (same seller)" do
    commentable = commentable_seller_post
    purchase = successful_purchase
    cc = CommentContext.new(comment: nil, commentable: commentable, purchase: purchase)

    assert permits?(SellerContext.logged_out, cc, :index?)
  end

  test "index? with purchase: denies when seller post and purchase seller differ" do
    commentable = commentable_seller_post
    another_product = links(:basic_user_product)
    another_seller = users(:basic_user)
    purchase = successful_purchase(seller: another_seller, link: another_product)
    cc = CommentContext.new(comment: nil, commentable: commentable, purchase: purchase)

    refute permits?(SellerContext.logged_out, cc, :index?)
  end

  # --- create? --------------------------------------------------------------
  test "create? grants access to seller's admin/marketing/owner" do
    commentable = commentable_seller_post
    comment = comment_for(commentable)
    cc = CommentContext.new(comment: comment, commentable: nil, purchase: nil)

    [@seller, @admin_for_seller, @marketing_for_seller].each do |u|
      assert permits?(SellerContext.new(user: u, seller: @seller), cc, :create?),
             "expected #{u.email} to be permitted"
    end
  end

  test "create? denies a buyer without a visible post" do
    commentable = commentable_seller_post(seller: @another_seller)
    comment = comment_for(commentable)
    cc = CommentContext.new(comment: comment, commentable: nil, purchase: nil)

    refute permits?(SellerContext.new(user: @buyer, seller: @buyer), cc, :create?)
  end

  test "create? denies logged-out user without a purchase" do
    commentable = commentable_product_post
    comment = comment_for(commentable)
    cc = CommentContext.new(comment: comment, commentable: nil, purchase: nil)

    refute permits?(SellerContext.logged_out, cc, :create?)
  end

  # --- update? --------------------------------------------------------------
  test "update? grants the author of the comment" do
    commentable = commentable_seller_post
    comment = Comment.create!(commentable: commentable, author: @comment_author,
                              content: "x", comment_type: Comment::COMMENT_TYPE_USER_SUBMITTED)
    cc = CommentContext.new(comment: comment, commentable: nil, purchase: nil)

    assert permits?(SellerContext.new(user: @comment_author, seller: @comment_author), cc, :update?)
  end

  test "update? denies the seller (not the author)" do
    commentable = commentable_seller_post
    comment = Comment.create!(commentable: commentable, author: @comment_author,
                              content: "x", comment_type: Comment::COMMENT_TYPE_USER_SUBMITTED)
    cc = CommentContext.new(comment: comment, commentable: nil, purchase: nil)

    refute permits?(SellerContext.new(user: @seller, seller: @seller), cc, :update?)
    refute permits?(SellerContext.new(user: @admin_for_seller, seller: @seller), cc, :update?)
  end

  test "update? grants when purchase matches the comment's purchase" do
    commentable = commentable_product_post
    purchase = successful_purchase
    comment = Comment.create!(commentable: commentable, purchase: purchase, author_name: "Buyer",
                              content: "x", comment_type: Comment::COMMENT_TYPE_USER_SUBMITTED)
    cc = CommentContext.new(comment: comment, commentable: nil, purchase: purchase)

    assert permits?(SellerContext.logged_out, cc, :update?)
  end

  test "update? denies when purchase does not match the comment's purchase" do
    commentable = commentable_product_post
    purchase = successful_purchase
    other_purchase = successful_purchase
    comment = Comment.create!(commentable: commentable, purchase: purchase, author_name: "Buyer",
                              content: "x", comment_type: Comment::COMMENT_TYPE_USER_SUBMITTED)
    cc = CommentContext.new(comment: comment, commentable: nil, purchase: other_purchase)

    refute permits?(SellerContext.logged_out, cc, :update?)
  end

  test "update? denies when both user and purchase are missing" do
    commentable = commentable_seller_post
    comment = Comment.create!(commentable: commentable, author: @buyer,
                              content: "x", comment_type: Comment::COMMENT_TYPE_USER_SUBMITTED)
    cc = CommentContext.new(comment: comment, commentable: nil, purchase: nil)

    refute permits?(SellerContext.logged_out, cc, :update?)
  end

  # --- destroy? -------------------------------------------------------------
  test "destroy? grants the author of the comment" do
    commentable = commentable_seller_post
    comment = Comment.create!(commentable: commentable, author: @comment_author,
                              content: "x", comment_type: Comment::COMMENT_TYPE_USER_SUBMITTED)
    cc = CommentContext.new(comment: comment, commentable: nil, purchase: nil)

    assert permits?(SellerContext.new(user: @comment_author, seller: @comment_author), cc, :destroy?)
  end

  test "destroy? grants seller and admin/marketing of seller's post; denies accountant + support" do
    commentable = commentable_seller_post
    comment = Comment.create!(commentable: commentable, author: @comment_author,
                              content: "x", comment_type: Comment::COMMENT_TYPE_USER_SUBMITTED)
    cc = CommentContext.new(comment: comment, commentable: nil, purchase: nil)

    assert permits?(SellerContext.new(user: @seller, seller: @seller), cc, :destroy?)
    assert permits?(SellerContext.new(user: @admin_for_seller, seller: @seller), cc, :destroy?)
    assert permits?(SellerContext.new(user: @marketing_for_seller, seller: @seller), cc, :destroy?)
    refute permits?(SellerContext.new(user: @accountant_for_seller, seller: @seller), cc, :destroy?)
    refute permits?(SellerContext.new(user: @support_for_seller, seller: @seller), cc, :destroy?)
  end

  test "destroy? grants when purchase matches the comment's purchase" do
    commentable = commentable_product_post
    purchase = successful_purchase
    comment = Comment.create!(commentable: commentable, purchase: purchase, author_name: "Buyer",
                              content: "x", comment_type: Comment::COMMENT_TYPE_USER_SUBMITTED)
    cc = CommentContext.new(comment: comment, commentable: nil, purchase: purchase)

    assert permits?(SellerContext.logged_out, cc, :destroy?)
  end

  test "destroy? denies when purchase does not match the comment's purchase" do
    commentable = commentable_product_post
    purchase = successful_purchase
    other_purchase = successful_purchase
    comment = Comment.create!(commentable: commentable, purchase: purchase, author_name: "Buyer",
                              content: "x", comment_type: Comment::COMMENT_TYPE_USER_SUBMITTED)
    cc = CommentContext.new(comment: comment, commentable: nil, purchase: other_purchase)

    refute permits?(SellerContext.logged_out, cc, :destroy?)
  end

  test "destroy? denies a stranger" do
    commentable = commentable_seller_post
    comment = Comment.create!(commentable: commentable, author: @comment_author,
                              content: "x", comment_type: Comment::COMMENT_TYPE_USER_SUBMITTED)
    cc = CommentContext.new(comment: comment, commentable: nil, purchase: nil)

    refute permits?(SellerContext.new(user: @visitor, seller: @visitor), cc, :destroy?)
  end
end
