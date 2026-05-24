# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. AssetPreview spec (398 LOC, 35 create() refs) is
# `:vcr`-tagged top-level. Every `create(:asset_preview*)` uploads a real
# image / video / gif blob via paperclip-style attachment + post-process
# (image scaling, dimension calculations) and asserts `asset_preview.file.url`
# matches `#{AWS_S3_ENDPOINT}/#{S3_BUCKET}/...`. Requires VCR cassettes for
# S3 PUT/HEAD + an ImageMagick/ffprobe stack the Minitest harness doesn't
# stub. Out of scope for mechanical model backfill.
#
# Original spec: spec/models/asset_preview_spec.rb
class AssetPreviewTest < ActiveSupport::TestCase
  test "TODO: migrate — :vcr + S3 blob uploads + ImageMagick post-process" do
    skip "Top-level :vcr; 35 create(:asset_preview*) refs through real image/video/gif blob attachments, S3 PUTs, ImageMagick dimension calculation. Out of scope for mechanical model backfill."
  end
end
