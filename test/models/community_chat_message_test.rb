require "test_helper"

class CommunityChatMessageTest < ActiveSupport::TestCase
  test "belongs_to :community" do
    assoc = CommunityChatMessage.reflect_on_association(:community)
    assert_equal :belongs_to, assoc.macro
  end

  test "belongs_to :user" do
    assoc = CommunityChatMessage.reflect_on_association(:user)
    assert_equal :belongs_to, assoc.macro
  end

  test "has_many :last_read_community_chat_messages with dependent destroy" do
    assoc = CommunityChatMessage.reflect_on_association(:last_read_community_chat_messages)
    assert_equal :has_many, assoc.macro
    assert_equal :destroy, assoc.options[:dependent]
  end

  test "validates presence of content" do
    msg = CommunityChatMessage.new(content: nil)
    assert_not msg.valid?
    assert_includes msg.errors[:content], "can't be blank"
  end

  test "validates length of content between 1 and 20000" do
    msg = community_chat_messages(:basic_user_message_in_named_seller_community)
    msg.content = ""
    assert_not msg.valid?
    msg.content = "a" * 20_001
    assert_not msg.valid?
    assert_includes msg.errors[:content].join, "20000"
    msg.content = "a" * 20_000
    assert msg.valid?
  end

  test ".recent_first returns messages in descending order of creation time" do
    community = communities(:named_seller_product_community)
    user = users(:basic_user)
    old_message = CommunityChatMessage.create!(community: community, user: user, content: "old", created_at: 2.days.ago)
    new_message = CommunityChatMessage.create!(community: community, user: user, content: "new", created_at: 1.day.ago)

    ordered = CommunityChatMessage.where(id: [old_message.id, new_message.id]).recent_first
    assert_equal [new_message, old_message], ordered.to_a
  end
end
