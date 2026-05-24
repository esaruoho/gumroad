# frozen_string_literal: true

require "test_helper"

class TriggerCommunityChatRecapRunJobTest < ActiveSupport::TestCase
  setup do
    CommunityChatRecapRun.delete_all
    CommunityChatRecap.delete_all
    CommunityChatMessage.delete_all
    GenerateCommunityChatRecapJob.clear
  end

  test "raises ArgumentError when recap_frequency is invalid" do
    err = assert_raises(ArgumentError) { TriggerCommunityChatRecapRunJob.new.perform("invalid") }
    assert_equal "Recap frequency must be daily or weekly", err.message
  end

  # --- daily ---

  test "daily: creates a daily recap run and marks it as finished when no messages exist" do
    from_date = Date.yesterday.beginning_of_day
    to_date = from_date.end_of_day

    runs_before = CommunityChatRecapRun.count
    recaps_before = CommunityChatRecap.count

    TriggerCommunityChatRecapRunJob.new.perform("daily")

    assert_equal runs_before + 1, CommunityChatRecapRun.count
    assert_equal recaps_before, CommunityChatRecap.count
    assert_empty GenerateCommunityChatRecapJob.jobs

    recap_run = CommunityChatRecapRun.last
    assert recap_run.recap_frequency_daily?
    assert_equal from_date.iso8601, recap_run.from_date.iso8601
    assert_equal to_date.iso8601, recap_run.to_date.iso8601
    assert_equal 0, recap_run.recaps_count
    assert recap_run.finished_at.present?
    assert recap_run.notified_at.present?
  end

  test "daily: creates a pending daily recap run when messages exist" do
    from_date = Date.yesterday.beginning_of_day
    to_date = from_date.end_of_day
    community = communities(:named_seller_product_community)
    CommunityChatMessage.create!(
      community: community,
      user: users(:basic_user),
      content: "hi",
      created_at: from_date + 1.hour,
    )

    runs_before = CommunityChatRecapRun.count
    recaps_before = CommunityChatRecap.count

    TriggerCommunityChatRecapRunJob.new.perform("daily")

    assert_equal runs_before + 1, CommunityChatRecapRun.count
    assert_equal recaps_before + 1, CommunityChatRecap.count

    recap_run = CommunityChatRecapRun.last
    assert recap_run.recap_frequency_daily?
    assert_equal from_date.iso8601, recap_run.from_date.iso8601
    assert_equal to_date.iso8601, recap_run.to_date.iso8601
    assert_equal 1, recap_run.recaps_count
    assert_nil recap_run.finished_at
    assert_nil recap_run.notified_at

    recap = CommunityChatRecap.last
    assert_equal community.id, recap.community_id
    assert_equal recap_run.id, recap.community_chat_recap_run_id
    assert recap.status_pending?

    assert_includes GenerateCommunityChatRecapJob.jobs.map { |j| j["args"] }, [recap.id]
  end

  test "daily: does not create a new recap run when one already exists" do
    from_date = Date.yesterday.beginning_of_day
    to_date = from_date.end_of_day
    CommunityChatRecapRun.create!(recap_frequency: "daily", from_date: from_date, to_date: to_date)

    runs_before = CommunityChatRecapRun.count
    recaps_before = CommunityChatRecap.count

    TriggerCommunityChatRecapRunJob.new.perform("daily")

    assert_equal runs_before, CommunityChatRecapRun.count
    assert_equal recaps_before, CommunityChatRecap.count
    assert_empty GenerateCommunityChatRecapJob.jobs
  end

  test "daily: uses the provided from_date" do
    custom_date = 2.days.ago.to_date.to_s

    runs_before = CommunityChatRecapRun.count
    TriggerCommunityChatRecapRunJob.new.perform("daily", custom_date)
    assert_equal runs_before + 1, CommunityChatRecapRun.count

    recap_run = CommunityChatRecapRun.last
    assert recap_run.recap_frequency_daily?
    assert_equal Date.parse(custom_date).beginning_of_day.iso8601, recap_run.from_date.iso8601
    assert_equal Date.parse(custom_date).end_of_day.iso8601, recap_run.to_date.iso8601
  end

  # --- weekly ---

  test "weekly: creates a weekly recap run and marks it as finished when no messages exist" do
    from_date = (Date.yesterday - 6.days).beginning_of_day
    to_date = (from_date + 6.days).end_of_day

    runs_before = CommunityChatRecapRun.count
    recaps_before = CommunityChatRecap.count

    TriggerCommunityChatRecapRunJob.new.perform("weekly")

    assert_equal runs_before + 1, CommunityChatRecapRun.count
    assert_equal recaps_before, CommunityChatRecap.count
    assert_empty GenerateCommunityChatRecapJob.jobs

    recap_run = CommunityChatRecapRun.last
    assert recap_run.recap_frequency_weekly?
    assert_equal from_date.iso8601, recap_run.from_date.iso8601
    assert_equal to_date.iso8601, recap_run.to_date.iso8601
    assert_equal 0, recap_run.recaps_count
    assert recap_run.finished_at.present?
    assert recap_run.notified_at.present?
  end

  test "weekly: creates a pending weekly recap run when messages exist" do
    from_date = (Date.yesterday - 6.days).beginning_of_day
    to_date = (from_date + 6.days).end_of_day
    community = communities(:named_seller_product_community)
    CommunityChatMessage.create!(
      community: community,
      user: users(:basic_user),
      content: "hi",
      created_at: from_date + 1.day,
    )

    runs_before = CommunityChatRecapRun.count
    recaps_before = CommunityChatRecap.count

    TriggerCommunityChatRecapRunJob.new.perform("weekly")

    assert_equal runs_before + 1, CommunityChatRecapRun.count
    assert_equal recaps_before + 1, CommunityChatRecap.count

    recap_run = CommunityChatRecapRun.last
    assert recap_run.recap_frequency_weekly?
    assert_equal from_date.iso8601, recap_run.from_date.iso8601
    assert_equal to_date.iso8601, recap_run.to_date.iso8601
    assert_equal 1, recap_run.recaps_count
    assert_nil recap_run.finished_at
    assert_nil recap_run.notified_at

    recap = CommunityChatRecap.last
    assert_equal community.id, recap.community_id
    assert_equal recap_run.id, recap.community_chat_recap_run_id
    assert recap.status_pending?

    assert_includes GenerateCommunityChatRecapJob.jobs.map { |j| j["args"] }, [recap.id]
  end

  test "weekly: does not create a new recap run when one already exists" do
    from_date = (Date.yesterday - 6.days).beginning_of_day
    to_date = (from_date + 6.days).end_of_day
    CommunityChatRecapRun.create!(recap_frequency: "weekly", from_date: from_date, to_date: to_date)

    runs_before = CommunityChatRecapRun.count
    recaps_before = CommunityChatRecap.count

    TriggerCommunityChatRecapRunJob.new.perform("weekly")

    assert_equal runs_before, CommunityChatRecapRun.count
    assert_equal recaps_before, CommunityChatRecap.count
    assert_empty GenerateCommunityChatRecapJob.jobs
  end

  test "weekly: uses the provided from_date" do
    custom_date = 14.days.ago.to_date.to_s

    runs_before = CommunityChatRecapRun.count
    TriggerCommunityChatRecapRunJob.new.perform("weekly", custom_date)
    assert_equal runs_before + 1, CommunityChatRecapRun.count

    recap_run = CommunityChatRecapRun.last
    assert recap_run.recap_frequency_weekly?
    assert_equal Date.parse(custom_date).beginning_of_day.iso8601, recap_run.from_date.iso8601
    assert_equal (Date.parse(custom_date) + 6.days).end_of_day.iso8601, recap_run.to_date.iso8601
  end
end
