# frozen_string_literal: true

require "test_helper"

class PaginatedCommunityChatMessagesPresenterTest < ActiveSupport::TestCase
  setup do
    @seller = users(:named_seller)
    @community = communities(:named_seller_product_community)
    CommunityChatMessage.delete_all
  end

  def make_message(created_at:, content: "msg")
    CommunityChatMessage.create!(community: @community, user: @seller, content:, created_at:)
  end

  test "initialize raises when timestamp missing" do
    err = assert_raises(ArgumentError) do
      PaginatedCommunityChatMessagesPresenter.new(community: @community, timestamp: nil, fetch_type: "older")
    end
    assert_equal "Invalid timestamp", err.message
  end

  test "initialize raises when fetch_type invalid" do
    err = assert_raises(ArgumentError) do
      PaginatedCommunityChatMessagesPresenter.new(community: @community, timestamp: Time.current.iso8601, fetch_type: "invalid")
    end
    assert_equal "Invalid fetch type", err.message
  end

  test "initialize accepts valid fetch types" do
    ts = Time.current.iso8601
    %w[older newer around].each do |ft|
      PaginatedCommunityChatMessagesPresenter.new(community: @community, timestamp: ts, fetch_type: ft)
    end
  end

  test "returns messages older than timestamp" do
    m1 = make_message(created_at: 30.minutes.ago)
    m2 = make_message(created_at: 20.minutes.ago)
    m3 = make_message(created_at: 10.minutes.ago)
    timestamp = 15.minutes.ago.iso8601

    props = PaginatedCommunityChatMessagesPresenter.new(community: @community, timestamp:, fetch_type: "older").props

    expected = [m1, m2].map { |m| CommunityChatMessagePresenter.new(message: m).props }
    assert_equal expected.sort_by { |h| h[:id] }, props[:messages].sort_by { |h| h[:id] }
    assert_nil props[:next_older_timestamp]
    assert_equal m3.created_at.iso8601, props[:next_newer_timestamp]
  end

  test "older: returns MESSAGES_PER_PAGE and next_older_timestamp when more than the page" do
    timestamp = 1.minute.ago.iso8601
    older = (1..101).map { |i| make_message(created_at: (i + 10).minutes.ago) }
    props = PaginatedCommunityChatMessagesPresenter.new(community: @community, timestamp:, fetch_type: "older").props

    assert_equal 100, props[:messages].length
    assert_equal older.last.created_at.iso8601, props[:next_older_timestamp]
    assert_nil props[:next_newer_timestamp]
  end

  test "returns messages newer than timestamp" do
    m1 = make_message(created_at: 10.minutes.ago)
    m2 = make_message(created_at: 20.minutes.ago)
    m3 = make_message(created_at: 30.minutes.ago)
    timestamp = 25.minutes.ago.iso8601

    props = PaginatedCommunityChatMessagesPresenter.new(community: @community, timestamp:, fetch_type: "newer").props

    expected = [m1, m2].map { |m| CommunityChatMessagePresenter.new(message: m).props }
    assert_equal expected.sort_by { |h| h[:id] }, props[:messages].sort_by { |h| h[:id] }
    assert_equal m3.created_at.iso8601, props[:next_older_timestamp]
    assert_nil props[:next_newer_timestamp]
  end

  test "newer: returns MESSAGES_PER_PAGE and next_newer_timestamp when more than the page" do
    newer = (1..101).map { |i| make_message(created_at: (i + 10).minutes.ago) }
    timestamp = newer.last.created_at.iso8601

    props = PaginatedCommunityChatMessagesPresenter.new(community: @community, timestamp:, fetch_type: "newer").props

    assert_equal 100, props[:messages].length
    assert_equal newer.first.created_at.iso8601, props[:next_newer_timestamp]
    assert_nil props[:next_older_timestamp]
  end

  test "around: returns equal number of older and newer messages" do
    total_messages = PaginatedCommunityChatMessagesPresenter::MESSAGES_PER_PAGE + 2
    messages = (1..total_messages).map do |i|
      make_message(content: "#{total_messages + 1 - i}", created_at: (i * 10).minutes.ago)
    end
    timestamp = (messages.find { |m| m.content == "52" }.created_at - 1.minute).iso8601

    props = PaginatedCommunityChatMessagesPresenter.new(community: @community, timestamp:, fetch_type: "around").props

    older_messages = messages.select { |m| m.content.to_i < 52 }
    newer_messages = messages.select { |m| m.content.to_i >= 52 }.reverse

    expected_contents = (older_messages.take(50) + newer_messages.take(50)).map { |m| m.content.to_i }.sort
    assert_equal 100, props[:messages].length
    assert_equal expected_contents, props[:messages].map { |m| m[:content].to_i }.sort
    assert_equal older_messages.last.created_at.iso8601, props[:next_older_timestamp]
    assert_equal newer_messages.last.created_at.iso8601, props[:next_newer_timestamp]
  end

  test "excludes deleted messages" do
    m1 = make_message(created_at: 3.minutes.ago)
    m2 = make_message(created_at: 2.minutes.ago)
    _m3 = make_message(created_at: 1.minute.ago)
    timestamp = m2.created_at.iso8601

    m1.update!(deleted_at: Time.current)

    props = PaginatedCommunityChatMessagesPresenter.new(community: @community, timestamp:, fetch_type: "older").props

    assert_empty props[:messages]
    assert_nil props[:next_older_timestamp]
    assert_equal timestamp, props[:next_newer_timestamp]
  end
end
