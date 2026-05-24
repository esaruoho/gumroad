# frozen_string_literal: true

require "test_helper"

class AssetPreviewPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  # Original RSpec `permissions :create?, :destroy? do … end` block.
  ACTIONS = %i[create? destroy?].freeze

  test "grants access to owner" do
    assert_policy_permits AssetPreviewPolicy, AssetPreview, :named_seller, *ACTIONS
  end

  test "denies access to accountant" do
    refute_policy_permits AssetPreviewPolicy, AssetPreview, :accountant_for_named_seller, *ACTIONS
  end

  test "grants access to admin" do
    assert_policy_permits AssetPreviewPolicy, AssetPreview, :admin_for_named_seller, *ACTIONS
  end

  test "grants access to marketing" do
    assert_policy_permits AssetPreviewPolicy, AssetPreview, :marketing_for_named_seller, *ACTIONS
  end

  test "denies access to support" do
    refute_policy_permits AssetPreviewPolicy, AssetPreview, :support_for_named_seller, *ACTIONS
  end
end
