# frozen_string_literal: true

require "test_helper"

class CommunityTest < ActiveSupport::TestCase
  test "belongs_to seller class_name User" do
    assoc = Community.reflect_on_association(:seller)
    assert_equal :belongs_to, assoc.macro
    assert_equal "User", assoc.class_name
  end

  test "belongs_to resource polymorphic" do
    assoc = Community.reflect_on_association(:resource)
    assert_equal :belongs_to, assoc.macro
    assert assoc.polymorphic?
  end

  test "has_many community_chat_messages with destroy" do
    assoc = Community.reflect_on_association(:community_chat_messages)
    assert_equal :has_many, assoc.macro
    assert_equal :destroy, assoc.options[:dependent]
  end

  test "has_many last_read_community_chat_messages with destroy" do
    assoc = Community.reflect_on_association(:last_read_community_chat_messages)
    assert_equal :has_many, assoc.macro
    assert_equal :destroy, assoc.options[:dependent]
  end

  test "has_many community_chat_recaps with destroy" do
    assoc = Community.reflect_on_association(:community_chat_recaps)
    assert_equal :has_many, assoc.macro
    assert_equal :destroy, assoc.options[:dependent]
  end

  test "validates seller_id uniqueness scoped to resource_id, resource_type, deleted_at" do
    existing = communities(:named_seller_product_community)
    dup = Community.new(
      seller_id: existing.seller_id,
      resource_type: existing.resource_type,
      resource_id: existing.resource_id,
    )
    assert_not dup.valid?
    assert_includes dup.errors[:seller_id], "has already been taken"
  end

  test "#name returns the resource name" do
    community = communities(:named_seller_product_community)
    assert_equal community.resource.name, community.name
  end

  test "#thumbnail_url returns the resource thumbnail url for email" do
    community = communities(:named_seller_product_community)
    expected = ActionController::Base.helpers.image_url("native_types/thumbnails/digital.png")
    assert_equal expected, community.thumbnail_url
  end
end
