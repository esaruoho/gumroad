# frozen_string_literal: true

require "test_helper"

class ContentModeration::ContentExtractorTest < ActiveSupport::TestCase
  test "TODO" do
    skip "migrate from spec/services/content_moderation/content_extractor_spec.rb " \
         "(asset_preview_jpg ActiveStorage attachment + heavy `allow(product).to receive(...)` " \
         "any-instance-style stubbing on a Product fixture; needs ProductRichContent fixture + " \
         "S3 download stub helper; deferred until ActiveStorage Disk service is wired up in the " \
         "Minitest CI lane)"
  end
end
