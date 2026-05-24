# frozen_string_literal: true

require "test_helper"

class CommunityChannelTest < ActionCable::Channel::TestCase
  tests CommunityChannel

  setup do
    @user = users(:community_buyer)
    @seller = users(:another_seller)
    @community = communities(:another_seller_product_community)
    Feature.activate_user(:communities, @seller)
  end

  teardown do
    Feature.deactivate_user(:communities, @seller)
  end

  def subscribe_to_channel
    subscribe(community_id: @community.external_id)
  end

  test "rejects subscription when user is not authenticated" do
    stub_connection current_user: nil
    subscribe_to_channel
    assert subscription.rejected?
  end

  test "rejects subscription when community_id is not provided" do
    stub_connection current_user: @user
    subscribe community_id: nil
    assert subscription.rejected?
  end

  test "rejects subscription when community is not found" do
    stub_connection current_user: @user
    subscribe community_id: "non_existent_id"
    assert subscription.rejected?
  end

  test "rejects subscription when user does not have access to community" do
    # community_buyer doesn't have a successful purchase of another_seller_product
    # unless we count community_buyer_purchase fixture. The original RSpec spec uses
    # a fresh user with no purchase to test the rejection path; replicate that.
    stranger = users(:basic_user)
    stub_connection current_user: stranger
    subscribe_to_channel
    assert subscription.rejected?
  end

  test "subscribes to the community channel when user has access" do
    # community_buyer has community_buyer_purchase against another_seller_product/seller.
    stub_connection current_user: @user
    subscribe_to_channel
    assert subscription.confirmed?
    assert_has_stream "community:community_#{@community.external_id}"
  end
end
