# frozen_string_literal: true

require "test_helper"

class GenerateSubscribePreviewJobTest < ActiveSupport::TestCase
  test "skipped: ActiveStorage attachment trap" do
    skip "GenerateSubscribePreviewJob attaches user.subscribe_preview via ActiveStorage blob.save!; covered by RSpec."
  end
end
