# frozen_string_literal: true

require "test_helper"

# Skip-stub: spec/models/dispute_evidence_spec.rb
# Reason: every `describe` block attaches files via Rack::Test::UploadedFile/ActiveStorage
# (policy_image, customer_communication_file, receipt_image — including big_file.txt and
# blah.txt fixtures). Validations under test depend on real attachment byte_size which the
# Minitest test_helper.rb ActiveStorage stub doesn't model. Fixture-hostile per skip-batch.
# Original spec: spec/models/dispute_evidence_spec.rb
class DisputeEvidenceTest < ActiveSupport::TestCase
  test "skipped: heavy ActiveStorage attachments (policy_image, customer_communication_file, receipt_image)" do
    skip "TODO: migrate spec/models/dispute_evidence_spec.rb — ActiveStorage attachment validations (file size + content type) on multiple fields. Covered by RSpec."
  end
end
