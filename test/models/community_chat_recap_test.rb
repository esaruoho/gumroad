require "test_helper"

class CommunityChatRecapTest < ActiveSupport::TestCase
  test "belongs_to :community_chat_recap_run" do
    assoc = CommunityChatRecap.reflect_on_association(:community_chat_recap_run)
    assert_equal :belongs_to, assoc.macro
    assert_not assoc.options[:optional]
  end

  test "belongs_to :community optional" do
    assoc = CommunityChatRecap.reflect_on_association(:community)
    assert_equal :belongs_to, assoc.macro
    assert assoc.options[:optional]
  end

  test "belongs_to :seller class_name User optional" do
    assoc = CommunityChatRecap.reflect_on_association(:seller)
    assert_equal :belongs_to, assoc.macro
    assert_equal "User", assoc.class_name
    assert assoc.options[:optional]
  end

  test "validates presence of summarized_message_count" do
    recap = CommunityChatRecap.new(summarized_message_count: nil)
    assert_not recap.valid?
    assert_includes recap.errors[:summarized_message_count], "can't be blank"
  end

  test "validates numericality of summarized_message_count >= 0" do
    recap = CommunityChatRecap.new(summarized_message_count: -1)
    assert_not recap.valid?
    assert recap.errors[:summarized_message_count].present?
  end

  test "validates presence of input_token_count" do
    recap = CommunityChatRecap.new(input_token_count: nil)
    assert_not recap.valid?
    assert_includes recap.errors[:input_token_count], "can't be blank"
  end

  test "validates numericality of input_token_count >= 0" do
    recap = CommunityChatRecap.new(input_token_count: -1)
    assert_not recap.valid?
    assert recap.errors[:input_token_count].present?
  end

  test "validates presence of output_token_count" do
    recap = CommunityChatRecap.new(output_token_count: nil)
    assert_not recap.valid?
    assert_includes recap.errors[:output_token_count], "can't be blank"
  end

  test "validates numericality of output_token_count >= 0" do
    recap = CommunityChatRecap.new(output_token_count: -1)
    assert_not recap.valid?
    assert recap.errors[:output_token_count].present?
  end

  test "validates presence of seller when status is finished" do
    recap = CommunityChatRecap.new(
      status: "finished",
      summarized_message_count: 0,
      input_token_count: 0,
      output_token_count: 0,
      seller: nil,
    )
    assert_not recap.valid?
    assert_includes recap.errors[:seller], "can't be blank"
  end

  test "does not validate presence of seller when status is not finished" do
    recap = CommunityChatRecap.new(
      status: "pending",
      summarized_message_count: 0,
      input_token_count: 0,
      output_token_count: 0,
      seller: nil,
      community_chat_recap_run: community_chat_recap_runs(:daily_recap_run),
    )
    recap.valid?
    assert_empty recap.errors[:seller]
  end

  test "defines string enum status with pending/finished/failed and status prefix" do
    assert_equal({ "pending" => "pending", "finished" => "finished", "failed" => "failed" }, CommunityChatRecap.statuses)
    recap = CommunityChatRecap.new(status: "pending")
    assert recap.status_pending?
    recap.status = "finished"
    assert recap.status_finished?
    recap.status = "failed"
    assert recap.status_failed?
  end
end
