# frozen_string_literal: true

require "test_helper"

class ImportedCustomerPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  READ_ACTIONS = %i[index?].freeze
  UPDATE_ACTIONS = %i[update?].freeze

  # index? — all roles permitted
  test "index? grants access to owner" do
    assert_policy_permits ImportedCustomerPolicy, ImportedCustomer, :named_seller, *READ_ACTIONS
  end

  test "index? grants access to accountant" do
    assert_policy_permits ImportedCustomerPolicy, ImportedCustomer, :accountant_for_named_seller, *READ_ACTIONS
  end

  test "index? grants access to admin" do
    assert_policy_permits ImportedCustomerPolicy, ImportedCustomer, :admin_for_named_seller, *READ_ACTIONS
  end

  test "index? grants access to marketing" do
    assert_policy_permits ImportedCustomerPolicy, ImportedCustomer, :marketing_for_named_seller, *READ_ACTIONS
  end

  test "index? grants access to support" do
    assert_policy_permits ImportedCustomerPolicy, ImportedCustomer, :support_for_named_seller, *READ_ACTIONS
  end

  # update? — owner + admin + support, denies accountant + marketing
  test "update? grants access to owner" do
    assert_policy_permits ImportedCustomerPolicy, ImportedCustomer, :named_seller, *UPDATE_ACTIONS
  end

  test "update? denies access to accountant" do
    refute_policy_permits ImportedCustomerPolicy, ImportedCustomer, :accountant_for_named_seller, *UPDATE_ACTIONS
  end

  test "update? grants access to admin" do
    assert_policy_permits ImportedCustomerPolicy, ImportedCustomer, :admin_for_named_seller, *UPDATE_ACTIONS
  end

  test "update? denies access to marketing" do
    refute_policy_permits ImportedCustomerPolicy, ImportedCustomer, :marketing_for_named_seller, *UPDATE_ACTIONS
  end

  test "update? grants access to support" do
    assert_policy_permits ImportedCustomerPolicy, ImportedCustomer, :support_for_named_seller, *UPDATE_ACTIONS
  end
end
