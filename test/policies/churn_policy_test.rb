# frozen_string_literal: true

require "test_helper"

class ChurnPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  ACTIONS = %i[show?].freeze

  setup do
    Feature.activate_user(:churn_analytics_enabled, users(:named_seller))
  end

  teardown do
    Feature.deactivate_user(:churn_analytics_enabled, users(:named_seller))
  end

  test "grants access to owner" do
    assert_policy_permits ChurnPolicy, :churn, :named_seller, *ACTIONS
  end

  test "grants access to accountant" do
    assert_policy_permits ChurnPolicy, :churn, :accountant_for_named_seller, *ACTIONS
  end

  test "grants access to admin" do
    assert_policy_permits ChurnPolicy, :churn, :admin_for_named_seller, *ACTIONS
  end

  test "grants access to marketing" do
    assert_policy_permits ChurnPolicy, :churn, :marketing_for_named_seller, *ACTIONS
  end

  test "grants access to support" do
    assert_policy_permits ChurnPolicy, :churn, :support_for_named_seller, *ACTIONS
  end

  test "denies access when churn_analytics_enabled feature is inactive" do
    Feature.deactivate_user(:churn_analytics_enabled, users(:named_seller))
    refute_policy_permits ChurnPolicy, :churn, :admin_for_named_seller, *ACTIONS
  end
end
