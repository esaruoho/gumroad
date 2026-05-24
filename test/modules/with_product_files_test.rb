# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration.
# Original: spec/modules/with_product_files_spec.rb (108 FactoryBot refs, 741 lines).
#
# Blocker for batch A backfill: this is the largest concern spec in the codebase
# (>700 lines, 108 FB refs). It tests the shared WithProductFiles module across
# Link, Installment, ProductInstallment and Variant hosts, with deep factory
# chains for each: product_files + product_files_archives + ZipArchive workers +
# subtitle_files + S3 keys. The skill's triage rule (P-M3) is unambiguous:
# >40 FB refs → skip-batch by default; 108 is nearly 3x that threshold.
# Migration requires bringing the full ProductFile/ProductFilesArchive/SubtitleFile
# fixture roster online (none present in `test/fixtures/` today), all with valid
# `S3_BASE_URL`-prefixed URLs per the `valid_url?` validation pitfall. Out of
# scope for batch A.
class ModulesWithProductFilesTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/modules/with_product_files_spec.rb — 108 FactoryBot refs / 741 lines (largest concern spec). Skill rule P-M3: >40 FB → skip-batch. Needs ProductFile + ProductFilesArchive + SubtitleFile fixture rosters with S3_BASE_URL-prefixed URLs."
  end
end
