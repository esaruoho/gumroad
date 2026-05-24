# frozen_string_literal: true

require "test_helper"

class Checkout::FormPresenterTest < ActiveSupport::TestCase
  setup do
    @seller = users(:named_seller)
    @user = users(:admin_for_named_seller)
    @presenter = Checkout::FormPresenter.new(pundit_user: SellerContext.new(user: @user, seller: @seller))
  end

  test "form_props returns the basic structure" do
    props = @presenter.form_props
    assert_equal ["discounts", "form", "upsells"], props[:pages]
    assert_kind_of Hash, props[:user]
    assert_includes [true, false], props[:user][:display_offer_code_field]
    assert props[:user].key?(:recommendation_type)
    assert_includes [true, false], props[:user][:tipping_enabled]
    assert_kind_of Array, props[:custom_fields]
    assert_kind_of Array, props[:products]
  end

  test "tipping_enabled reflects seller flag" do
    @seller.update_columns(flags: (@seller.flags || 0) | User.flag_mapping["flags"][:tipping_enabled])
    assert_equal true, @presenter.form_props[:user][:tipping_enabled]
  end

  test "display_offer_code_field reflects seller flag" do
    @seller.update_columns(flags: (@seller.flags || 0) | User.flag_mapping["flags"][:display_offer_code_field])
    assert_equal true, @presenter.form_props[:user][:display_offer_code_field]
  end
end
