# frozen_string_literal: true

require "test_helper"

class Checkout::UpsellsPresenterTest < ActiveSupport::TestCase
  setup do
    @seller = users(:named_seller)
    @pundit_user = SellerContext.new(user: @seller, seller: @seller)
  end

  test "upsells_props returns empty upsells for seller without upsells" do
    presenter = Checkout::UpsellsPresenter.new(
      pundit_user: @pundit_user,
      upsells: @seller.upsells.none,
      pagination: nil
    )
    props = presenter.upsells_props

    assert_equal ["discounts", "form", "upsells"], props[:pages]
    assert_equal [], props[:upsells]
    assert_nil props[:pagination]
    assert_kind_of Array, props[:products]
    # named_seller_product is visible_and_not_archived
    product_ids = props[:products].map { |p| p[:id] }
    assert_includes product_ids, links(:named_seller_product).external_id
  end

  test "products entries include name and native_type" do
    presenter = Checkout::UpsellsPresenter.new(
      pundit_user: @pundit_user,
      upsells: @seller.upsells.none,
      pagination: nil
    )
    product = presenter.upsells_props[:products].find { |p| p[:id] == links(:named_seller_product).external_id }
    assert_equal links(:named_seller_product).name, product[:name]
    assert_equal links(:named_seller_product).native_type, product[:native_type]
    assert_includes [true, false], product[:has_multiple_versions]
  end
end
