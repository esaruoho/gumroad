# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. CommunityChatRecapRun spec (217 LOC, 24 create()
# refs) uses shoulda-matchers `is_expected.to have_many(:community_chat_recaps)`
# DSL plus the recap-completion state machine across CommunityChatRecap +
# CommunityChatMessage + Community + Seller factory chain (5+ associations
# per test). The shoulda-matchers DSL has no Minitest port in this lane,
# and the recap-completion path enqueues SendCommunityChatRecapNotificationJob
# / ContactingCreatorMailer that needs job-enqueue assertions. Out of scope
# for mechanical model backfill.
#
# Original spec: spec/models/community_chat_recap_run_spec.rb
class CommunityChatRecapRunTest < ActiveSupport::TestCase
  test "TODO: migrate — shoulda-matchers + recap state machine + Sidekiq enqueue" do
    skip "24 create() refs through CommunityChatRecapRun + CommunityChatRecap + CommunityChatMessage + Community + Seller chain; shoulda-matchers `is_expected.to` DSL + SendCommunityChatRecapNotificationJob enqueue assertions. Out of scope for mechanical model backfill."
  end
end
