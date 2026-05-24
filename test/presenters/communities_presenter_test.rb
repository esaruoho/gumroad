# frozen_string_literal: true

require "test_helper"

class CommunitiesPresenterTest < ActiveSupport::TestCase
  setup do
    @seller = users(:another_seller)
    @buyer = users(:community_buyer)
    @community = communities(:another_seller_product_community)
    # Fixtures bypass save callbacks; populate external_ids that the presenter needs.
    @seller.update_column(:external_id, "seller_ext_id") if @seller.external_id.blank?
    @buyer.update_column(:external_id, "buyer_ext_id") if @buyer.external_id.blank?
  end

  def with_communities_feature
    Feature.activate_user(:communities, @seller)
    yield
  ensure
    Feature.deactivate_user(:communities, @seller)
  end

  test "returns empty props when no accessible communities" do
    # buyer is a community_buyer but feature inactive
    presenter = CommunitiesPresenter.new(current_user: @buyer)
    assert_equal(
      { has_products: false, communities: [], notification_settings: {} },
      presenter.props
    )
  end

  test "returns accessible communities and notification settings" do
    setting = CommunityNotificationSetting.create!(user: @buyer, seller: @seller, recap_frequency: "daily")
    with_communities_feature do
      presenter = CommunitiesPresenter.new(current_user: @buyer)
      props = presenter.props
      assert_equal false, props[:has_products]
      assert_equal [CommunityPresenter.new(community: @community, current_user: @buyer).props], props[:communities]
      assert_equal({ @seller.external_id => { recap_frequency: "daily" } }, props[:notification_settings])
    end
    setting.destroy!
  end

  test "returns empty notification_settings when none exist" do
    with_communities_feature do
      props = CommunitiesPresenter.new(current_user: @buyer).props
      assert_equal({}, props[:notification_settings])
    end
  end

  test "computes unread count and last_read timestamp" do
    msg1 = CommunityChatMessage.create!(community: @community, user: @seller, content: "first", created_at: 3.minutes.ago)
    CommunityChatMessage.create!(community: @community, user: @seller, content: "second", created_at: 2.minutes.ago)
    CommunityChatMessage.create!(community: @community, user: @seller, content: "third", created_at: 1.minute.ago)
    LastReadCommunityChatMessage.create!(user: @buyer, community: @community, community_chat_message: msg1)

    with_communities_feature do
      community_props = CommunitiesPresenter.new(current_user: @buyer).props[:communities].sole
      assert_equal msg1.created_at.iso8601, community_props[:last_read_community_chat_message_created_at]
      assert_equal 2, community_props[:unread_count]
    end
  end

  test "returns all messages as unread when no last_read exists" do
    CommunityChatMessage.create!(community: @community, user: @seller, content: "first", created_at: 3.minutes.ago)
    CommunityChatMessage.create!(community: @community, user: @seller, content: "second", created_at: 2.minutes.ago)
    CommunityChatMessage.create!(community: @community, user: @seller, content: "third", created_at: 1.minute.ago)

    with_communities_feature do
      community_props = CommunitiesPresenter.new(current_user: @buyer).props[:communities].sole
      assert_nil community_props[:last_read_community_chat_message_created_at]
      assert_equal 3, community_props[:unread_count]
    end
  end
end
