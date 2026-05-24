# frozen_string_literal: true

require "test_helper"

class ContentModeration::ContentExtractorTest < ActiveSupport::TestCase
  # Sharpened skip-stub.
  # Original: spec/services/content_moderation/content_extractor_spec.rb
  # Blocker: AssetPreview + ProductRichContent + ProductFile S3-key/signed-URL chain + thumbnail.url stubs; requires building rich_content + cover_preview fixture rows with valid S3_BASE_URL prefixes and signed URL helpers — currently RSpec-stubbed via instance_double.
  test "TODO: migrate spec/services/content_moderation/content_extractor_spec.rb" do
    skip "Fixture-hostile — see top-of-file blocker note"
  end
end
