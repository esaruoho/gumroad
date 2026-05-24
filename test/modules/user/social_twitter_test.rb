# frozen_string_literal: true

require "test_helper"

class User::SocialTwitterTest < ActiveSupport::TestCase
  setup do
    skip "User::SocialTwitter spec depends on VCR cassettes + the $twitter client + S3 round trips — out of scope for the Minitest CI lane. Covered by RSpec integration."
  end

  test "covered by RSpec lane" do
    flunk "unreachable"
  end
end
