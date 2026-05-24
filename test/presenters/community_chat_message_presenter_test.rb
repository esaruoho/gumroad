# frozen_string_literal: true

require "test_helper"

class CommunityChatMessagePresenterTest < ActiveSupport::TestCase
  test "returns message data in the expected format" do
    message = community_chat_messages(:basic_user_message_in_named_seller_community)
    buyer = users(:basic_user)
    community = communities(:named_seller_product_community)
    presenter = CommunityChatMessagePresenter.new(message:)

    assert_equal(
      {
        id: message.external_id,
        community_id: community.external_id,
        content: message.content,
        created_at: message.created_at.iso8601,
        updated_at: message.updated_at.iso8601,
        user: {
          id: buyer.external_id,
          name: buyer.display_name,
          avatar_url: buyer.avatar_url,
          is_seller: false
        }
      },
      presenter.props
    )
  end

  test "sets is_seller to true when message is from the community seller" do
    message = community_chat_messages(:named_seller_message_in_named_seller_community)
    presenter = CommunityChatMessagePresenter.new(message:)
    assert_equal true, presenter.props[:user][:is_seller]
  end
end
