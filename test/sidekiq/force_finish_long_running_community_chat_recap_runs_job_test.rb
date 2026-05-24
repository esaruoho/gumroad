# frozen_string_literal: true

require "test_helper"

class ForceFinishLongRunningCommunityChatRecapRunsJobTest < ActiveSupport::TestCase
  test "does nothing when recap run is already finished" do
    run = community_chat_recap_runs(:force_finish_already_finished_run)
    recap = community_chat_recaps(:force_finish_already_finished_recap)
    finished_at_was = run.finished_at
    status_was = recap.status

    ForceFinishLongRunningCommunityChatRecapRunsJob.new.perform

    assert_equal status_was, recap.reload.status
    assert_equal finished_at_was.to_i, run.reload.finished_at.to_i
  end

  test "does not update recaps when run is recent" do
    run = community_chat_recap_runs(:force_finish_running_recent_run)
    recap = community_chat_recaps(:force_finish_running_recent_recap)

    ForceFinishLongRunningCommunityChatRecapRunsJob.new.perform

    assert_nil run.reload.finished_at
    assert_equal "pending", recap.reload.status
  end

  test "marks pending recaps as failed when run is stuck" do
    run = community_chat_recap_runs(:force_finish_running_stuck_run)
    recap = community_chat_recaps(:force_finish_running_stuck_recap_pending)

    ForceFinishLongRunningCommunityChatRecapRunsJob.new.perform

    recap.reload
    run.reload
    assert_equal "failed", recap.status
    assert_equal "Recap run cancelled because it took longer than 6 hours to complete", recap.error_message
    assert_not_nil run.finished_at
  end

  test "leaves non-pending recaps untouched but still finishes stuck run" do
    run = community_chat_recap_runs(:force_finish_running_stuck_run_finished_recap)
    recap = community_chat_recaps(:force_finish_running_stuck_recap_finished)

    ForceFinishLongRunningCommunityChatRecapRunsJob.new.perform

    recap.reload
    run.reload
    assert_equal "finished", recap.status
    assert_nil recap.error_message
    assert_not_nil run.finished_at
  end
end
