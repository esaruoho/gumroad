# frozen_string_literal: true

require "test_helper"

class Admin::ProductPresenter::CardTest < ActiveSupport::TestCase
  setup do
    @admin_user = users(:admin_user)
    @user = users(:named_seller)
    @product = links(:basic_user_product)
    @user = @product.user
    @pundit_user = SellerContext.new(user: @admin_user, seller: @admin_user)
  end

  def presenter(product: @product)
    Admin::ProductPresenter::Card.new(product: product, pundit_user: @pundit_user)
  end

  test "#props returns the basic product fields" do
    props = presenter.props
    assert_equal @product.external_id, props[:external_id]
    assert_equal @product.name, props[:name]
    assert_equal @product.long_url, props[:long_url]
    assert_equal @product.price_cents, props[:price_cents]
    assert_equal @product.price_currency_type, props[:currency_code]
    assert_equal @product.unique_permalink, props[:unique_permalink]
    assert_equal @product.preview_url, props[:preview_url]
    assert_equal @product.price_formatted, props[:price_formatted]
    assert_equal @product.created_at, props[:created_at]
    assert_equal @product.admins_can_generate_url_redirects, props[:admins_can_generate_url_redirects]
    assert_equal @product.html_safe_description, props[:html_safe_description]
    assert_equal @product.alive?, props[:alive]
    assert_equal @product.is_adult?, props[:is_adult]
    assert_equal @product.content_moderation_disabled?, props[:content_moderation_disabled]
    assert_equal @product.is_tiered_membership?, props[:is_tiered_membership]
    assert_equal @product.updated_at, props[:updated_at]
    assert_equal @product.deleted_at, props[:deleted_at]
    assert_match(/cover_placeholder.*\.png/, props[:cover_placeholder_url])
  end

  test "#props returns user hash with required fields" do
    props = presenter.props
    assert_equal @user.external_id, props[:user][:external_id]
    assert_equal @user.display_name, props[:user][:name]
    assert_equal false, props[:user][:suspended]
    assert_equal false, props[:user][:flagged_for_tos_violation]
  end

  test "#props returns user suspended=true when user is suspended" do
    @user.update!(user_risk_state: "suspended_for_fraud")
    assert_equal true, presenter.props[:user][:suspended]
  end

  test "#props returns user flagged_for_tos_violation=true when applicable" do
    @user.update!(user_risk_state: "flagged_for_tos_violation")
    assert_equal true, presenter.props[:user][:flagged_for_tos_violation]
  end

  test "#props returns empty array for active_integrations when product has none" do
    assert_equal [], presenter.props[:active_integrations]
  end

  test "#props returns alive=true for an alive product" do
    assert_equal true, presenter.props[:alive]
  end

  test "#props returns alive=false and sets deleted_at when product is deleted" do
    @product.mark_deleted!
    props = presenter.props
    assert_equal false, props[:alive]
    refute_nil props[:deleted_at]
  end

  test "#props returns is_adult=true when product is adult" do
    @product.update!(is_adult: true)
    assert_equal true, presenter.props[:is_adult]
  end

  test "#props returns admins_can_generate_url_redirects=false when product has no files" do
    @product.product_files.alive.each(&:mark_deleted!) if @product.respond_to?(:product_files)
    assert_equal false, presenter.props[:admins_can_generate_url_redirects]
  end

  test "#props returns html_safe_description with proper link attributes" do
    @product.update!(description: "Check out http://example.com")
    desc = presenter.props[:html_safe_description]
    assert_includes desc, 'target="_blank"'
    assert_includes desc, 'rel="noopener noreferrer nofollow"'
  end

  test "#props returns nil for html_safe_description when no description" do
    @product.update_column(:description, nil)
    assert_nil presenter.props[:html_safe_description]
  end

  test "#props returns alive_product_files for products with files" do
    file1 = @product.product_files.create!(url: "#{S3_BASE_URL}specs/file1.pdf", position: 1)
    file2 = @product.product_files.create!(url: "#{S3_BASE_URL}specs/file2.pdf", position: 2)

    props = presenter.props
    ids = props[:alive_product_files].map { |f| f[:external_id] }
    assert_includes ids, file1.external_id
    assert_includes ids, file2.external_id
  end

  test "#props excludes deleted product files" do
    deleted_file = @product.product_files.create!(url: "#{S3_BASE_URL}specs/del.pdf", position: 1)
    deleted_file.update_column(:deleted_at, 1.day.ago)
    props = presenter.props
    refute_includes props[:alive_product_files].map { |f| f[:external_id] }, deleted_file.external_id
  end
end
