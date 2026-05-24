# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration.
# Original: spec/sidekiq/send_post_blast_emails_job_spec.rb (50 FB refs, 335 lines).
#
# Blocker for batch 6b-B backfill: `:freeze_time`, builds `create(:audience_post,
# :published)` + `create(:blast, :just_requested)` + `create(:active_follower)` +
# multi-segment audience (followers, customers, affiliates) and exercises post-blast
# email delivery to thousands-of-recipients code paths with custom `expect_sent_count`
# helper. AudiencePost is an Installment subclass with the full post + blast + audience
# fixture chain (`audience_post`/`installment_blasts` tables — not seeded). Out of scope.
class SendPostBlastEmailsJobTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/sidekiq/send_post_blast_emails_job_spec.rb — 50 FB refs / 335 lines, :freeze_time + audience_post + blast + active_follower fixture chain across followers/customers/affiliates segments. installment_blasts table has no fixtures, custom expect_sent_count helper. Out of scope."
  end
end
