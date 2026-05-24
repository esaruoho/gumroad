# frozen_string_literal: true

require "test_helper"

class Onetime::ResolveStuckDisputeEvidenceTest < ActiveSupport::TestCase
  test ".process resolves only unresolved evidence whose dispute reached a terminal state" do
    stuck_lost = dispute_evidences(:resolve_stuck_lost)
    stuck_won = dispute_evidences(:resolve_stuck_won)
    still_active = dispute_evidences(:resolve_still_active)
    already_resolved = dispute_evidences(:resolve_already_resolved)

    ReplicaLagWatcher.stub(:watch, nil) do
      Onetime::ResolveStuckDisputeEvidence.process
    end

    assert stuck_lost.reload.resolved?
    assert_equal DisputeEvidence::RESOLUTION_REJECTED, stuck_lost.resolution
    assert_includes stuck_lost.error_message, "state=lost"

    assert stuck_won.reload.resolved?
    assert_equal DisputeEvidence::RESOLUTION_REJECTED, stuck_won.resolution
    assert_includes stuck_won.error_message, "state=won"

    assert_not still_active.reload.resolved?
    assert_equal DisputeEvidence::RESOLUTION_SUBMITTED, already_resolved.reload.resolution
  end
end
