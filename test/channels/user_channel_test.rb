# frozen_string_literal: true

require "test_helper"

class UserChannelTest < ActionCable::Channel::TestCase
  tests UserChannel

  setup do
    @user = users(:community_buyer)
    @seller = users(:another_seller)
    @community = communities(:another_seller_product_community)
    Feature.activate_user(:communities, @seller)
  end

  teardown do
    Feature.deactivate_user(:communities, @seller)
  end

  # --- #subscribed ---

  test "rejects subscription when user is not authenticated" do
    stub_connection current_user: nil
    subscribe
    assert subscription.rejected?
  end

  test "subscribes to the user channel when authenticated" do
    stub_connection current_user: @user
    subscribe
    assert subscription.confirmed?
    assert_has_stream "user:user_#{@user.external_id}"
  end

  # --- #receive ---

  test "rejects message when community_id is not provided (latest_community_info)" do
    stub_connection current_user: @user
    subscribe
    perform :receive, { type: UserChannel::LATEST_COMMUNITY_INFO_TYPE }
    assert subscription.rejected?
  end

  test "rejects message when community is not found (latest_community_info)" do
    stub_connection current_user: @user
    subscribe
    perform :receive, { type: UserChannel::LATEST_COMMUNITY_INFO_TYPE, community_id: "non_existent_id" }
    assert subscription.rejected?
  end

  test "rejects message when user does not have access to community" do
    stranger = users(:basic_user)
    stub_connection current_user: stranger
    subscribe
    perform :receive, { type: UserChannel::LATEST_COMMUNITY_INFO_TYPE, community_id: @community.external_id }
    assert subscription.rejected?
  end

  test "broadcasts community info when user has access" do
    stub_connection current_user: @user
    subscribe
    type = UserChannel::LATEST_COMMUNITY_INFO_TYPE
    stream = "user:user_#{@user.external_id}"

    assert_broadcasts(stream, 1) do
      perform :receive, { type:, community_id: @community.external_id }
    end

    assert subscription.confirmed?
  end

  test "does nothing when type is unknown" do
    stub_connection current_user: @user
    subscribe
    stream = "user:user_#{@user.external_id}"

    assert_no_broadcasts(stream) do
      perform :receive, { type: "unknown_type" }
    end

    assert subscription.confirmed?
  end
end
