# frozen_string_literal: true

require "test_helper"

class UserSocialGoogleTest < ActiveSupport::TestCase
  test "skipped: requires VCR + ActiveStorage avatar_variant + any_instance_of stubbing for Google OAuth flow" do
    skip "VCR + ActiveStorage avatar_variant + any_instance_of stubbing required; covered by integration runs"
  end
end
