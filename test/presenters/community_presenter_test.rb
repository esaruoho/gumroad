# frozen_string_literal: true

require "test_helper"

class CommunityPresenterTest < ActiveSupport::TestCase
  setup do
    @seller = users(:another_seller)
    @buyer = users(:community_buyer)
    @community = communities(:another_seller_product_community)
  end

  test "returns appropriate props" do
    presenter = CommunityPresenter.new(community: @community, current_user: @buyer)
    expected = {
      id: @community.external_id,
      name: @community.name,
      thumbnail_url: @community.thumbnail_url,
      seller: {
        id: @seller.external_id,
        name: @seller.display_name,
        avatar_url: @seller.avatar_url,
      },
      last_read_community_chat_message_created_at: nil,
      unread_count: 0,
    }
    assert_equal expected, presenter.props
  end

  test "uses provided extras instead of querying the database" do
    last_read_at = 1.day.ago
    presenter = CommunityPresenter.new(
      community: @community,
      current_user: @buyer,
      extras: {
        last_read_community_chat_message_created_at: last_read_at.iso8601,
        unread_count: 5,
      }
    )
    props = presenter.props
    assert_equal last_read_at.iso8601, props[:last_read_community_chat_message_created_at]
    assert_equal 5, props[:unread_count]
  end

  test "returns the last read message timestamp and unread count from DB" do
    msg1 = CommunityChatMessage.create!(community: @community, user: @seller, content: "first", created_at: 3.minutes.ago)
    CommunityChatMessage.create!(community: @community, user: @seller, content: "second", created_at: 2.minutes.ago)
    CommunityChatMessage.create!(community: @community, user: @seller, content: "third", created_at: 1.minute.ago)
    LastReadCommunityChatMessage.create!(user: @buyer, community: @community, community_chat_message: msg1)

    presenter = CommunityPresenter.new(community: @community, current_user: @buyer)
    props = presenter.props
    assert_equal msg1.created_at.iso8601, props[:last_read_community_chat_message_created_at]
    assert_equal 2, props[:unread_count]
  end
end
