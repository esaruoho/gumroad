# frozen_string_literal: true

require "test_helper"

class ThumbnailPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  ACTIONS = %i[create? destroy?].freeze

  test "grants access to owner" do
    assert_policy_permits ThumbnailPolicy, Thumbnail, :named_seller, *ACTIONS
  end

  test "denies access to accountant" do
    refute_policy_permits ThumbnailPolicy, Thumbnail, :accountant_for_named_seller, *ACTIONS
  end

  test "grants access to admin" do
    assert_policy_permits ThumbnailPolicy, Thumbnail, :admin_for_named_seller, *ACTIONS
  end

  test "grants access to marketing" do
    assert_policy_permits ThumbnailPolicy, Thumbnail, :marketing_for_named_seller, *ACTIONS
  end

  test "denies access to support" do
    refute_policy_permits ThumbnailPolicy, Thumbnail, :support_for_named_seller, *ACTIONS
  end
end
