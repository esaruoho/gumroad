# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration.
# Original: spec/sidekiq/send_community_chat_recap_notifications_job_spec.rb (8 FB refs, 91 lines).
#
# Blocker for batch 6b-B backfill: chains `create(:community_chat_recap_run)` +
# `create(:community)` (resource: product, with `community_chat_enabled: true`
# branch toggle) + `create(:community_chat_recap)` + `create(:community_notification_setting)`
# + `create(:purchase, ...)` and asserts on `have_enqueued_mail(CommunityChatRecapMailer,
# :community_chat_recap_notification).with(...)`. The community + recap + notification_setting
# fixture chain isn't seeded; no fixtures in test/fixtures for community_chat_recap_runs,
# community_chat_recaps, communities, or community_notification_settings. Out of scope.
class SendCommunityChatRecapNotificationsJobTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/sidekiq/send_community_chat_recap_notifications_job_spec.rb — chains community_chat_recap_run + community (resource: product, community_chat_enabled toggle) + community_chat_recap + community_notification_setting + purchase fixtures. None of these tables have fixtures in test/fixtures yet; spec uses 4 distinct branch contexts. Out of scope."
  end
end
