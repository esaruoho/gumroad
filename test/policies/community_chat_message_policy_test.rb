# frozen_string_literal: true

require "test_helper"

class CommunityChatMessagePolicyTest < ActiveSupport::TestCase
  # `basic_user` posted the message; `named_seller` owns the community resource.
  # `referrer_user` is a third party with no relationship to either.

  def context_for(user_fixture)
    SellerContext.new(user: users(user_fixture), seller: users(:named_seller))
  end

  def message
    community_chat_messages(:basic_user_message_in_named_seller_community)
  end

  test "update? — permits the message creator" do
    assert CommunityChatMessagePolicy.new(context_for(:basic_user), message).update?
  end

  test "update? — denies the community seller" do
    refute CommunityChatMessagePolicy.new(context_for(:named_seller), message).update?
  end

  test "update? — denies an unrelated user" do
    refute CommunityChatMessagePolicy.new(context_for(:referrer_user), message).update?
  end

  test "destroy? — permits the message creator" do
    assert CommunityChatMessagePolicy.new(context_for(:basic_user), message).destroy?
  end

  test "destroy? — permits the community seller" do
    assert CommunityChatMessagePolicy.new(context_for(:named_seller), message).destroy?
  end

  test "destroy? — denies an unrelated user" do
    refute CommunityChatMessagePolicy.new(context_for(:referrer_user), message).destroy?
  end
end
