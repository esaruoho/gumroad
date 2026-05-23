# frozen_string_literal: true

require "test_helper"

class Checkout::FormPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  SHOW_ACTIONS = %i[show?].freeze
  UPDATE_ACTIONS = %i[update?].freeze

  # show? — all roles permitted
  test "show? grants access to owner" do
    assert_policy_permits Checkout::FormPolicy, :form, :named_seller, *SHOW_ACTIONS
  end

  test "show? grants access to accountant" do
    assert_policy_permits Checkout::FormPolicy, :form, :accountant_for_named_seller, *SHOW_ACTIONS
  end

  test "show? grants access to admin" do
    assert_policy_permits Checkout::FormPolicy, :form, :admin_for_named_seller, *SHOW_ACTIONS
  end

  test "show? grants access to marketing" do
    assert_policy_permits Checkout::FormPolicy, :form, :marketing_for_named_seller, *SHOW_ACTIONS
  end

  test "show? grants access to support" do
    assert_policy_permits Checkout::FormPolicy, :form, :support_for_named_seller, *SHOW_ACTIONS
  end

  # update? — owner + admin + marketing only
  test "update? grants access to owner" do
    assert_policy_permits Checkout::FormPolicy, :form, :named_seller, *UPDATE_ACTIONS
  end

  test "update? denies accountant" do
    refute_policy_permits Checkout::FormPolicy, :form, :accountant_for_named_seller, *UPDATE_ACTIONS
  end

  test "update? grants access to admin" do
    assert_policy_permits Checkout::FormPolicy, :form, :admin_for_named_seller, *UPDATE_ACTIONS
  end

  test "update? grants access to marketing" do
    assert_policy_permits Checkout::FormPolicy, :form, :marketing_for_named_seller, *UPDATE_ACTIONS
  end

  test "update? denies support" do
    refute_policy_permits Checkout::FormPolicy, :form, :support_for_named_seller, *UPDATE_ACTIONS
  end
end
