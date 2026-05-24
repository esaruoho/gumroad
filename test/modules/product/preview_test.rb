# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration.
# Original: spec/modules/product/preview_spec.rb (13 FactoryBot refs, 136 lines).
#
# Blocker for batch A backfill: the spec is tagged `:vcr` and every example does
# `link.preview = uploaded_file(...)` followed by assertions on `link.main_preview`
# (an AssetPreview ActiveStorage attachment). The preview= setter triggers
# ActiveStorage analyzers (image dimensions, video probe via FFmpeg), VCR-recorded
# Oembed HTTP probes for the video case, and `HTTParty.head(link.preview_url)` which
# is a live request. Per skill pitfall in `leaf-backfill-pitfalls.md`, ActiveStorage
# attachments hit MinIO/S3 and require the disk-service swap recipe — but that only
# covers attach/upload, not the analyzer + Oembed + HTTParty chain this spec asserts
# on. Out of scope for batch A.
class ModulesProductPreviewTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/modules/product/preview_spec.rb — :vcr-tagged AssetPreview chain (image/video analyzers, Oembed, HTTParty.head live); needs both the disk-service shim from leaf-backfill-pitfalls.md AND a VCR/HTTP-stub harness for preview_url probing."
  end
end
