# frozen_string_literal: true

require "test_helper"

class Admin::ProductPresenter::MultipleMatchesTest < ActiveSupport::TestCase
  setup do
    @user = users(:named_seller)
    @product = links(:named_seller_product)
    @presenter = Admin::ProductPresenter::MultipleMatches.new(product: @product)
  end

  test "returns a hash with all expected keys" do
    props = @presenter.props
    [:external_id, :name, :created_at, :long_url, :price_formatted, :user].each do |key|
      assert_includes props.keys, key
    end
  end

  test "returns the correct field values" do
    props = @presenter.props
    assert_equal @product.external_id, props[:external_id]
    assert_equal @product.name, props[:name]
    assert_equal @product.created_at, props[:created_at]
    assert_equal @product.long_url, props[:long_url]
    assert_equal @product.price_formatted, props[:price_formatted]
  end

  test "user association returns user information" do
    props = @presenter.props
    assert_equal(
      { external_id: @user.external_id, name: @user.display_name },
      props[:user]
    )
  end

  test "user association returns the correct user external_id and name" do
    props = @presenter.props
    assert_equal @user.external_id, props[:user][:external_id]
    assert_equal @user.display_name, props[:user][:name]
  end
end
