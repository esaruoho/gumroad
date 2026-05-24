# frozen_string_literal: true

require "test_helper"

class CommunityChatRecapGeneratorServiceTest < ActiveSupport::TestCase
  test "summary bounds and limits constants are configured" do
    assert_equal 1000, CommunityChatRecapGeneratorService::MAX_MESSAGES_TO_SUMMARIZE
    assert_equal 500, CommunityChatRecapGeneratorService::MAX_SUMMARY_LENGTH
    assert_equal 1, CommunityChatRecapGeneratorService::MIN_SUMMARY_BULLET_POINTS
    assert_equal 5, CommunityChatRecapGeneratorService::MAX_SUMMARY_BULLET_POINTS
    assert_equal 10, CommunityChatRecapGeneratorService::OPENAI_REQUEST_TIMEOUT_IN_SECONDS
  end

  test "daily and weekly system prompts reference creator/customer roles" do
    daily = CommunityChatRecapGeneratorService::DAILY_SUMMARY_SYSTEM_PROMPT
    weekly = CommunityChatRecapGeneratorService::WEEKLY_SUMMARY_SYSTEM_PROMPT

    assert_includes daily, "creator"
    assert_includes daily, "<strong>"
    assert_includes daily, "<ul>"
    assert_match(/maximum #{CommunityChatRecapGeneratorService::MAX_SUMMARY_LENGTH} characters/, daily)

    assert_includes weekly, "weekly summary"
    assert_includes weekly, "<strong>"
  end

  # TODO: full recap generation (15 FB refs in the original) iterates
  # community_chat_recap_runs/messages, calls OpenAI under VCR cassettes, and
  # writes recap rows with bullet-point summaries. That requires the OpenAI VCR
  # fixture corpus and a deeper communities + messages chain than this lane has.
  # Original: spec/services/community_chat_recap_generator_service_spec.rb
end
