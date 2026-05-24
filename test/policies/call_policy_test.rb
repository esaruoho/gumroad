# frozen_string_literal: true

require "test_helper"

class CallPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  # When the call belongs to the seller (named_seller)
  test "grants access to owner" do
    assert_policy_permits CallPolicy, calls(:named_seller_call), :named_seller, :update?
  end

  test "denies access to accountant" do
    refute_policy_permits CallPolicy, calls(:named_seller_call), :accountant_for_named_seller, :update?
  end

  test "grants access to admin" do
    assert_policy_permits CallPolicy, calls(:named_seller_call), :admin_for_named_seller, :update?
  end

  test "denies access to marketing" do
    refute_policy_permits CallPolicy, calls(:named_seller_call), :marketing_for_named_seller, :update?
  end

  test "grants access to support" do
    assert_policy_permits CallPolicy, calls(:named_seller_call), :support_for_named_seller, :update?
  end

  # When the call belongs to another seller — all roles denied
  test "denies owner for another seller's call" do
    refute_policy_permits CallPolicy, calls(:another_seller_call), :named_seller, :update?
  end

  test "denies accountant for another seller's call" do
    refute_policy_permits CallPolicy, calls(:another_seller_call), :accountant_for_named_seller, :update?
  end

  test "denies admin for another seller's call" do
    refute_policy_permits CallPolicy, calls(:another_seller_call), :admin_for_named_seller, :update?
  end

  test "denies marketing for another seller's call" do
    refute_policy_permits CallPolicy, calls(:another_seller_call), :marketing_for_named_seller, :update?
  end

  test "denies support for another seller's call" do
    refute_policy_permits CallPolicy, calls(:another_seller_call), :support_for_named_seller, :update?
  end
end
