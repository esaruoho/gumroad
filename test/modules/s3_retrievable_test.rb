# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration.
# Original: spec/modules/s3_retrievable_spec.rb (0 FactoryBot refs but 210 lines, AWS-live).
#
# Blocker for batch A backfill: the spec defines an anonymous AR model via
# `create_mock_model` (similar to test/modules/elasticsearch_model_async_callbacks_test.rb's
# helper) and the *behaviour-under-test* is `restore_deleted_s3_object!` /
# `confirm_s3_key!` — both perform real `Aws::S3::Resource.new.bucket(S3_BUCKET).object(...)`
# uploads/downloads/deletes against the dev MinIO bucket. The full original suite cannot
# run under WebMock.disable_net_connect! without an AWS S3 stub harness (a separate piece
# of test infrastructure not present in the Minitest lane today). Half-migrating only the
# pure-string methods (`unique_url_identifier`, `s3_filename`, `s3_extension`,
# `s3_display_extension`, `s3_display_name`, `s3_directory_uri`) would skip the AWS-bound
# half and violate the "don't half-migrate" rule. Out of scope for batch A.
class ModulesS3RetrievableTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/modules/s3_retrievable_spec.rb — restore_deleted_s3_object! / confirm_s3_key! / .s3 / .with_s3_key examples perform real AWS S3 (MinIO) calls; needs an Aws::S3 stub harness for the Minitest lane."
  end
end
