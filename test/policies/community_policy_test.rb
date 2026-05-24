# frozen_string_literal: true

require "test_helper"

class CommunityPolicyTest < ActiveSupport::TestCase
  def named_seller_community
    communities(:named_seller_product_community)
  end

  def another_seller_community
    communities(:another_seller_product_community)
  end

  def ctx(user_fixture, seller_fixture = :named_seller)
    SellerContext.new(user: users(user_fixture), seller: users(seller_fixture))
  end

  def permit?(context, record, action)
    CommunityPolicy.new(context, record).public_send(action)
  end

  def activate_communities!
    Feature.activate_user(:communities, users(:named_seller))
    Feature.activate_user(:communities, users(:another_seller))
  end

  def deactivate_communities!
    Feature.deactivate_user(:communities, users(:named_seller))
    Feature.deactivate_user(:communities, users(:another_seller))
  end

  # ---------------------------------------------------------------------------
  # index? — with accessible communities (feature active on both sellers)
  # ---------------------------------------------------------------------------

  test "index?: grants access to owner when communities are accessible" do
    activate_communities!
    assert permit?(ctx(:named_seller), Community, :index?)
  ensure
    deactivate_communities!
  end

  test "index?: denies accountant when communities are accessible" do
    activate_communities!
    refute permit?(ctx(:accountant_for_named_seller), Community, :index?)
  ensure
    deactivate_communities!
  end

  test "index?: denies admin when communities are accessible" do
    activate_communities!
    refute permit?(ctx(:admin_for_named_seller), Community, :index?)
  ensure
    deactivate_communities!
  end

  test "index?: denies marketing when communities are accessible" do
    activate_communities!
    refute permit?(ctx(:marketing_for_named_seller), Community, :index?)
  ensure
    deactivate_communities!
  end

  test "index?: denies support when communities are accessible" do
    activate_communities!
    refute permit?(ctx(:support_for_named_seller), Community, :index?)
  ensure
    deactivate_communities!
  end

  test "index?: grants access to buyer with purchased product" do
    activate_communities!
    purchases(:community_buyer_purchase) # ensure loaded
    context = SellerContext.new(user: users(:community_buyer), seller: users(:another_seller))
    assert permit?(context, Community, :index?)
  ensure
    deactivate_communities!
  end

  test "index?: denies seller who has a product but no active communities" do
    # basic_user owns basic_user_product, but has no Community row.
    Feature.activate_user(:communities, users(:basic_user))
    context = SellerContext.new(user: users(:basic_user), seller: users(:named_seller))
    refute permit?(context, Community, :index?)
  ensure
    Feature.deactivate_user(:communities, users(:basic_user))
  end

  # ---------------------------------------------------------------------------
  # index? — feature inactive
  # ---------------------------------------------------------------------------

  test "index?: denies owner when communities feature is inactive" do
    refute permit?(ctx(:named_seller), Community, :index?)
  end

  test "index?: denies accountant when communities feature is inactive" do
    refute permit?(ctx(:accountant_for_named_seller), Community, :index?)
  end

  test "index?: denies admin when communities feature is inactive" do
    refute permit?(ctx(:admin_for_named_seller), Community, :index?)
  end

  test "index?: denies marketing when communities feature is inactive" do
    refute permit?(ctx(:marketing_for_named_seller), Community, :index?)
  end

  test "index?: denies support when communities feature is inactive" do
    refute permit?(ctx(:support_for_named_seller), Community, :index?)
  end

  test "index?: denies buyer when communities feature is inactive" do
    purchases(:community_buyer_purchase)
    context = SellerContext.new(user: users(:community_buyer), seller: users(:another_seller))
    refute permit?(context, Community, :index?)
  end

  # ---------------------------------------------------------------------------
  # show? — feature active
  # ---------------------------------------------------------------------------

  test "show?: grants seller access to own community" do
    activate_communities!
    assert permit?(ctx(:named_seller), named_seller_community, :show?)
  ensure
    deactivate_communities!
  end

  test "show?: denies seller access to other seller's community" do
    activate_communities!
    refute permit?(ctx(:named_seller), another_seller_community, :show?)
  ensure
    deactivate_communities!
  end

  test "show?: grants buyer access to community of purchased product" do
    activate_communities!
    purchases(:community_buyer_purchase)
    context = SellerContext.new(user: users(:community_buyer), seller: users(:named_seller))
    assert permit?(context, another_seller_community, :show?)
  ensure
    deactivate_communities!
  end

  test "show?: denies buyer access to community of unpurchased product" do
    activate_communities!
    context = SellerContext.new(user: users(:community_buyer), seller: users(:named_seller))
    refute permit?(context, named_seller_community, :show?)
  ensure
    deactivate_communities!
  end

  test "show?: denies team member access to seller's community" do
    activate_communities!
    refute permit?(ctx(:admin_for_named_seller), named_seller_community, :show?)
  ensure
    deactivate_communities!
  end

  test "show?: denies team member access to other seller's community" do
    activate_communities!
    refute permit?(ctx(:admin_for_named_seller), another_seller_community, :show?)
  ensure
    deactivate_communities!
  end

  # ---------------------------------------------------------------------------
  # show? — feature inactive
  # ---------------------------------------------------------------------------

  test "show?: denies owner when communities feature is inactive" do
    refute permit?(ctx(:named_seller), named_seller_community, :show?)
  end

  test "show?: denies buyer when communities feature is inactive" do
    purchases(:community_buyer_purchase)
    context = SellerContext.new(user: users(:community_buyer), seller: users(:named_seller))
    refute permit?(context, another_seller_community, :show?)
  end

  test "show?: denies team member when communities feature is inactive" do
    refute permit?(ctx(:admin_for_named_seller), named_seller_community, :show?)
  end

  # ---------------------------------------------------------------------------
  # show? — resource deleted / chat disabled
  # ---------------------------------------------------------------------------

  test "show?: denies owner when community's resource is deleted" do
    Feature.activate_user(:communities, users(:named_seller))
    links(:named_seller_product).mark_deleted!
    refute permit?(ctx(:named_seller), named_seller_community, :show?)
  ensure
    Feature.deactivate_user(:communities, users(:named_seller))
  end

  test "show?: denies team member when community's resource is deleted" do
    Feature.activate_user(:communities, users(:named_seller))
    links(:named_seller_product).mark_deleted!
    refute permit?(ctx(:admin_for_named_seller), named_seller_community, :show?)
  ensure
    Feature.deactivate_user(:communities, users(:named_seller))
  end

  test "show?: denies owner when community chat is disabled on the product" do
    Feature.activate_user(:communities, users(:named_seller))
    links(:named_seller_product).update!(community_chat_enabled: false)
    refute permit?(ctx(:named_seller), named_seller_community, :show?)
  ensure
    Feature.deactivate_user(:communities, users(:named_seller))
  end

  test "show?: denies team member when community chat is disabled on the product" do
    Feature.activate_user(:communities, users(:named_seller))
    links(:named_seller_product).update!(community_chat_enabled: false)
    refute permit?(ctx(:admin_for_named_seller), named_seller_community, :show?)
  ensure
    Feature.deactivate_user(:communities, users(:named_seller))
  end
end
