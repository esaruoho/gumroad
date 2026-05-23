# frozen_string_literal: true

require "test_helper"

class Products::AffiliatedPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  ACTIONS = %i[index?].freeze

  test "grants access to owner" do
    assert_policy_permits Products::AffiliatedPolicy, :affiliated, :named_seller, *ACTIONS
  end

  test "grants access to accountant" do
    assert_policy_permits Products::AffiliatedPolicy, :affiliated, :accountant_for_named_seller, *ACTIONS
  end

  test "grants access to admin" do
    assert_policy_permits Products::AffiliatedPolicy, :affiliated, :admin_for_named_seller, *ACTIONS
  end

  test "grants access to marketing" do
    assert_policy_permits Products::AffiliatedPolicy, :affiliated, :marketing_for_named_seller, *ACTIONS
  end

  test "grants access to support" do
    assert_policy_permits Products::AffiliatedPolicy, :affiliated, :support_for_named_seller, *ACTIONS
  end
end
