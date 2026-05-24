# frozen_string_literal: true

require "test_helper"

class ProductTaggingTest < ActiveSupport::TestCase
  setup do
    @creator = users(:ptg_creator)
    @product_a = links(:ptg_product_a)
    @product_b = links(:ptg_product_b)
    @product_c = links(:ptg_product_c)

    @product_a.tag!("tag a")
    @product_a.tag!("tag b")
    @product_a.tag!("tag c")

    @product_b.tag!("tag b")
    @product_b.tag!("tag c")

    @product_c.tag!("tag b")
  end

  test ".sorted_by_tags_usage_for_products returns tags sorted by number of tagged products" do
    products = Link.where(id: [@product_a.id, @product_b.id, @product_c.id])
    product_taggings = ProductTagging.sorted_by_tags_usage_for_products(products)
    assert_equal ["tag b", "tag c", "tag a"], product_taggings.to_a.map(&:tag).map(&:name)
  end

  test ".owned_by_user returns tags owned by a user" do
    product_taggings = ProductTagging.owned_by_user(@creator).where(product_id: [@product_a.id, @product_b.id, @product_c.id])
    assert_equal "tag b", product_taggings.first.tag.name
  end

  test ".has_tag_name returns tags by name" do
    product_taggings = ProductTagging.has_tag_name("tag b")
                                     .where(product_id: [@product_a.id, @product_b.id, @product_c.id])
    assert_equal "tag b", product_taggings.first.tag.name
  end
end
