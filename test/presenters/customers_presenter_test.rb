# frozen_string_literal: true

require "test_helper"

class CustomersPresenterTest < ActiveSupport::TestCase
  setup do
    @seller = users(:named_seller)
    @pundit_user = SellerContext.new(user: @seller, seller: @seller)
  end

  test "customers_props returns top-level keys with empty customers" do
    presenter = CustomersPresenter.new(pundit_user: @pundit_user, customers: [], pagination: nil, count: 0)
    props = presenter.customers_props

    assert_nil props[:pagination]
    assert_nil props[:product_id]
    assert_equal [], props[:customers]
    assert_equal 0, props[:count]
    assert_kind_of Array, props[:products]
    assert_equal "usd", props[:currency_type]
    assert_kind_of Array, props[:countries]
    assert_includes [true, false], props[:can_ping]
    assert_includes [true, false], props[:show_refund_fee_notice]
    assert_equal false, props[:license_uses_filter_enabled]
  end

  test "customers_props sets product_id when product passed in" do
    product = links(:named_seller_product)
    presenter = CustomersPresenter.new(pundit_user: @pundit_user, customers: [], pagination: nil, product:, count: 0)
    assert_equal product.external_id, presenter.customers_props[:product_id]
  end
end
