# frozen_string_literal: true

require "test_helper"

# Migrated from spec/presenters/comment_presenter_spec.rb (deleted in c9c93ee5).
# Fixtures: comments(:basic_user_comment_on_published_post) authored by basic_user
# on installments(:published_post) which belongs to named_seller.
class CommentPresenterTest < ActiveSupport::TestCase
  setup do
    @seller = users(:named_seller)
    @commenter = users(:basic_user)
    @post = installments(:published_post)
    @comment = comments(:basic_user_comment_on_published_post)
    @default_avatar = ActionController::Base.helpers.image_url("gumroad-default-avatar-5.png")
  end

  def presenter(pundit_user:, comment: @comment, purchase: nil)
    CommentPresenter.new(pundit_user:, comment:, purchase:)
  end

  test "returns full comment component props for the commenter" do
    pundit_user = SellerContext.new(user: @commenter, seller: @commenter)
    travel_to(@comment.created_at) do
      props = presenter(pundit_user:).comment_component_props
      assert_equal @comment.external_id, props[:id]
      assert_nil props[:parent_id]
      assert_equal @commenter.external_id, props[:author_id]
      assert_equal @commenter.display_name, props[:author_name]
      assert_equal @default_avatar, props[:author_avatar_url]
      assert_nil props[:purchase_id]
      assert_equal({ original: @comment.content, formatted: CGI.escapeHTML(@comment.content) }, props[:content])
      assert_equal @comment.created_at.iso8601, props[:created_at]
      assert_equal "less than a minute ago", props[:created_at_humanized]
      assert_equal 0, props[:depth]
      assert_equal true, props[:is_editable]
      assert_equal true, props[:is_deletable]
    end
  end

  test "escapes HTML in content while preserving original" do
    content = %(That's a great article!<script type="text/html">console.log("Executing evil script...")</script>)
    @comment.update!(content:)
    pundit_user = SellerContext.new(user: @commenter, seller: @commenter)
    result = presenter(pundit_user:).comment_component_props[:content]
    assert_equal content, result[:original]
    assert_equal "That&#39;s a great article!&lt;script type=&quot;text/html&quot;&gt;console.log(&quot;Executing evil script...&quot;)&lt;/script&gt;", result[:formatted]
  end

  test "auto-links URLs in formatted content" do
    content = %(Nice article! Please visit my website at https://example.com)
    @comment.update!(content:)
    pundit_user = SellerContext.new(user: @commenter, seller: @commenter)
    result = presenter(pundit_user:).comment_component_props[:content]
    assert_equal content, result[:original]
    assert_equal %(Nice article! Please visit my website at <a href="https://example.com" target="_blank" rel="noopener noreferrer nofollow">https://example.com</a>), result[:formatted]
  end

  test "seller (post author) cannot edit but can delete" do
    pundit_user = SellerContext.new(user: @seller, seller: @seller)
    props = presenter(pundit_user:).comment_component_props
    assert_equal true, props[:is_deletable]
    assert_equal false, props[:is_editable]
  end

  test "team admin for seller cannot edit but can delete" do
    admin = users(:admin_for_named_seller)
    pundit_user = SellerContext.new(user: admin, seller: @seller)
    props = presenter(pundit_user:).comment_component_props
    assert_equal true, props[:is_deletable]
    assert_equal false, props[:is_editable]
  end

  test "unrelated signed-in user cannot edit or delete" do
    other = users(:another_seller)
    pundit_user = SellerContext.new(user: other, seller: other)
    props = presenter(pundit_user:).comment_component_props
    assert_equal false, props[:is_deletable]
    assert_equal false, props[:is_editable]
  end

  test "logged-out viewer cannot edit or delete and gets default avatar" do
    pundit_user = SellerContext.logged_out
    props = presenter(pundit_user:).comment_component_props
    assert_equal false, props[:is_deletable]
    assert_equal false, props[:is_editable]
    assert_equal @default_avatar, props[:author_avatar_url]
  end

  test "author without avatar gets default avatar URL" do
    pundit_user = SellerContext.new(user: @commenter, seller: @commenter)
    assert_equal @default_avatar, presenter(pundit_user:).comment_component_props[:author_avatar_url]
  end

  # :with_avatar trait requires ActiveStorage attachment (S3/MinIO); skipped per
  # leaf-backfill ActiveStorage pitfall — covered by user_test avatar tests.
end
