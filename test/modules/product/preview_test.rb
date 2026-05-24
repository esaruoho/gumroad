# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during mig-b sweep.
# ActiveStorage / file-upload spec: uses Rack::Test::UploadedFile against
# png/mov/jpg/garbage fixtures, attaches them via `link.preview = file`,
# asserts on AssetPreview.alive.count, asserts HTTParty.head/get on
# preview_url (real S3-shaped attached blob URL). Spec is :vcr-tagged and
# every test exercises the ActiveStorage attach pipeline.
#
# Documented skip-ActiveStorage rule: don't try to migrate `.attach` /
# `.blob.url` / `.thumbnail_url` against non-pre-attached fixtures.
#
# Original spec: spec/modules/product/preview_spec.rb
class Product::PreviewTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — ActiveStorage-bound, requires manual rewrite" do
    skip "TODO: migrate spec/modules/product/preview_spec.rb (ActiveStorage attach pipeline + VCR)"
  end
end
