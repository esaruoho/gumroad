# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during fixtures-only migration.
# ActiveStorage-heavy: the presenter reads `dispute_evidence.receipt_image`
# and `dispute_evidence.policy_image` (byte_size, filename, key) plus signed_id
# blobs. The ActiveStorage S3 attach path is hostile to the macOS/Minitest CI
# lane (Makara blacklist + missing MinIO) per gumroad-fixtures-migration skill.
#
# Original spec: spec/presenters/dispute_evidence_page_presenter_spec.rb (deleted)
class DisputeEvidencePagePresenterTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — ActiveStorage blobs hostile to Minitest CI" do
    skip "TODO: migrate spec/presenters/dispute_evidence_page_presenter_spec.rb (1 FB ref, ActiveStorage receipt/policy image blobs)"
  end
end
