# frozen_string_literal: true

require "test_helper"

class Product::UtilsTest < ActiveSupport::TestCase
  fixtures :links, :users

  test ".f fetches product from unique permalink" do
    product = links(:product_utils_find_me_a_hex)
    assert_equal product, Link.f(product.unique_permalink)
  end

  test ".f fetches product from custom permalink" do
    product = links(:product_utils_find_me_a_hex)
    assert_equal product, Link.f("FindMeAHex")
  end

  test ".f raises an error when custom permalink matches more than one product" do
    assert_raises(ActiveRecord::RecordNotUnique) { Link.f("custom") }
  end

  test ".f fetches the correct product when scoped to a given user" do
    product_b = links(:product_utils_custom_b)
    assert_equal product_b, Link.f("custom", product_b.user_id)
  end

  test ".f fetches product from id" do
    product = links(:product_utils_find_me_a_hex)
    assert_equal product, Link.f(product.id)
  end

  test ".f raises error if no product found" do
    assert_raises(ActiveRecord::RecordNotFound) { Link.f(42) }
  end
end
