# frozen_string_literal: true

require "test_helper"

class FightDisputesJobTest < ActiveSupport::TestCase
  test "enqueues FightDisputeJob only for non-resolved, past-window, non-terminal disputes" do
    ready = dispute_evidences(:fight_disputes_ready)
    not_ready = dispute_evidences(:fight_disputes_not_ready)
    resolved = dispute_evidences(:fight_disputes_resolved)
    lost = dispute_evidences(:fight_disputes_lost)
    won = dispute_evidences(:fight_disputes_won)

    FightDisputeJob.jobs.clear
    FightDisputesJob.new.perform
    enqueued_ids = FightDisputeJob.jobs.map { |j| j["args"].first }

    assert_includes enqueued_ids, ready.dispute.id
    refute_includes enqueued_ids, not_ready.dispute.id
    refute_includes enqueued_ids, resolved.dispute.id
    refute_includes enqueued_ids, lost.dispute.id
    refute_includes enqueued_ids, won.dispute.id
  end
end
