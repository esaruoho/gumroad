# frozen_string_literal: true

require "test_helper"

class LastReadCommunityChatMessageTest < ActiveSupport::TestCase
  setup do
    @user = users(:named_seller)
    @community = communities(:last_read_test_community)
    # Author for messages — different from @user so unread counts include them.
    @author = users(:basic_user)
  end

  def create_message(created_at:)
    CommunityChatMessage.create!(community: @community, user: @author, content: "msg #{created_at.to_i}", created_at: created_at, updated_at: created_at)
  end

  # --- associations ---

  test "belongs_to associations are wired" do
    assoc = LastReadCommunityChatMessage.reflect_on_association(:user)
    assert_equal :belongs_to, assoc.macro
    assert_equal :belongs_to, LastReadCommunityChatMessage.reflect_on_association(:community).macro
    assert_equal :belongs_to, LastReadCommunityChatMessage.reflect_on_association(:community_chat_message).macro
  end

  # --- validation ---

  test "validates uniqueness of user_id scoped to community_id" do
    m1 = create_message(created_at: 1.hour.ago)
    LastReadCommunityChatMessage.create!(user: @user, community: @community, community_chat_message: m1)
    dup = LastReadCommunityChatMessage.new(user: @user, community: @community, community_chat_message: m1)
    refute dup.valid?
    assert_includes dup.errors[:user_id], "has already been taken"
  end

  # --- .set! ---

  test "set! creates a new record when none exists" do
    m1 = create_message(created_at: 1.hour.ago)
    assert_difference -> { LastReadCommunityChatMessage.count }, 1 do
      LastReadCommunityChatMessage.set!(user_id: @user.id, community_id: @community.id, community_chat_message_id: m1.id)
    end
  end

  test "set! updates the record when given message is newer than existing" do
    m1 = create_message(created_at: 1.hour.ago)
    m2 = create_message(created_at: Time.current)
    LastReadCommunityChatMessage.create!(user: @user, community: @community, community_chat_message: m1)
    assert_no_difference -> { LastReadCommunityChatMessage.count } do
      LastReadCommunityChatMessage.set!(user_id: @user.id, community_id: @community.id, community_chat_message_id: m2.id)
    end
    last_read = LastReadCommunityChatMessage.find_by!(user: @user, community: @community)
    assert_equal m2.id, last_read.community_chat_message_id
  end

  test "set! does not update when given message is older than existing" do
    m1 = create_message(created_at: 1.hour.ago)
    m_older = create_message(created_at: 2.hours.ago)
    LastReadCommunityChatMessage.create!(user: @user, community: @community, community_chat_message: m1)
    assert_no_difference -> { LastReadCommunityChatMessage.count } do
      LastReadCommunityChatMessage.set!(user_id: @user.id, community_id: @community.id, community_chat_message_id: m_older.id)
    end
    last_read = LastReadCommunityChatMessage.find_by!(user: @user, community: @community)
    assert_equal m1.id, last_read.community_chat_message_id
  end

  # --- .unread_count_for ---

  test "unread_count_for returns count of messages newer than last read" do
    m1 = create_message(created_at: 3.hours.ago)
    create_message(created_at: 2.hours.ago)
    create_message(created_at: 1.hour.ago)
    LastReadCommunityChatMessage.create!(user: @user, community: @community, community_chat_message: m1)
    assert_equal 2, LastReadCommunityChatMessage.unread_count_for(user_id: @user.id, community_id: @community.id)
  end

  test "unread_count_for uses provided message when specified" do
    create_message(created_at: 3.hours.ago)
    m2 = create_message(created_at: 2.hours.ago)
    create_message(created_at: 1.hour.ago)
    assert_equal 1, LastReadCommunityChatMessage.unread_count_for(user_id: @user.id, community_id: @community.id, community_chat_message_id: m2.id)
  end

  test "unread_count_for returns all community messages when no last-read record" do
    create_message(created_at: 3.hours.ago)
    create_message(created_at: 2.hours.ago)
    create_message(created_at: 1.hour.ago)
    assert_equal 3, LastReadCommunityChatMessage.unread_count_for(user_id: @user.id, community_id: @community.id)
  end

  test "unread_count_for only counts alive messages" do
    m1 = create_message(created_at: 3.hours.ago)
    m2 = create_message(created_at: 2.hours.ago)
    create_message(created_at: 1.hour.ago)
    LastReadCommunityChatMessage.create!(user: @user, community: @community, community_chat_message: m1)
    m2.mark_deleted!
    assert_equal 1, LastReadCommunityChatMessage.unread_count_for(user_id: @user.id, community_id: @community.id)
  end
end
