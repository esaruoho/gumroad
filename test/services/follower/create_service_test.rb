# frozen_string_literal: true

require "test_helper"

class Follower::CreateServiceTest < ActiveSupport::TestCase
  # Sharpened skip-stub.
  # Original: spec/services/follower/create_service_spec.rb
  # Blocker: Active/cancelled/deleted Follower lifecycle + FollowerMailer enqueue + multi-user logged_in_user flow. RSpec uses `have_enqueued_mail` + `allow_any_instance_of(Follower).receive(:save!).and_wrap_original` for replica-DB race tests.
  test "TODO: migrate spec/services/follower/create_service_spec.rb" do
    skip "Fixture-hostile — see top-of-file blocker note"
  end
end
