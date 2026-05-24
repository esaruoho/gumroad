# frozen_string_literal: true

require "test_helper"

class AffiliatesHelperTest < ActionView::TestCase
  test "affiliate_products_select_data returns selected ids and full list" do
    selected = links(:named_seller_product)
    other1   = links(:basic_user_product)
    other2   = links(:another_seller_product)
    products = [other1, selected, other2]
    affiliate = affiliates(:direct_affiliate_for_helper)

    tag_ids, tag_list = affiliate_products_select_data(affiliate, products)

    assert_equal [selected.external_id], tag_ids
    assert_equal products.map { |p| { id: p.external_id, label: p.name } }, tag_list
  end
end
