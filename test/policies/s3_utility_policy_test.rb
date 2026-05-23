# frozen_string_literal: true

require "test_helper"

class S3UtilityPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  ACTIONS = %i[generate_multipart_signature? current_utc_time_string? cdn_url_for_blob?].freeze

  # Original RSpec passed the policy class itself as the record; preserve that.
  RECORD = S3UtilityPolicy

  test "grants access to owner" do
    assert_policy_permits S3UtilityPolicy, RECORD, :named_seller, *ACTIONS
  end

  test "denies access to accountant" do
    refute_policy_permits S3UtilityPolicy, RECORD, :accountant_for_named_seller, *ACTIONS
  end

  test "grants access to admin" do
    assert_policy_permits S3UtilityPolicy, RECORD, :admin_for_named_seller, *ACTIONS
  end

  test "grants access to marketing" do
    assert_policy_permits S3UtilityPolicy, RECORD, :marketing_for_named_seller, *ACTIONS
  end

  test "denies access to support" do
    refute_policy_permits S3UtilityPolicy, RECORD, :support_for_named_seller, *ACTIONS
  end
end
