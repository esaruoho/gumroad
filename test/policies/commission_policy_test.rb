# frozen_string_literal: true

require "test_helper"

class CommissionPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  # When the commission belongs to the seller (named_seller)
  test "grants access to owner" do
    assert_policy_permits CommissionPolicy, commissions(:named_seller_commission), :named_seller, :update?
  end

  test "denies access to accountant" do
    refute_policy_permits CommissionPolicy, commissions(:named_seller_commission), :accountant_for_named_seller, :update?
  end

  test "grants access to admin" do
    assert_policy_permits CommissionPolicy, commissions(:named_seller_commission), :admin_for_named_seller, :update?
  end

  test "denies access to marketing" do
    refute_policy_permits CommissionPolicy, commissions(:named_seller_commission), :marketing_for_named_seller, :update?
  end

  test "grants access to support" do
    assert_policy_permits CommissionPolicy, commissions(:named_seller_commission), :support_for_named_seller, :update?
  end

  # When the commission belongs to another seller — all roles denied
  test "denies owner for another seller's commission" do
    refute_policy_permits CommissionPolicy, commissions(:another_seller_commission), :named_seller, :update?
  end

  test "denies accountant for another seller's commission" do
    refute_policy_permits CommissionPolicy, commissions(:another_seller_commission), :accountant_for_named_seller, :update?
  end

  test "denies admin for another seller's commission" do
    refute_policy_permits CommissionPolicy, commissions(:another_seller_commission), :admin_for_named_seller, :update?
  end

  test "denies marketing for another seller's commission" do
    refute_policy_permits CommissionPolicy, commissions(:another_seller_commission), :marketing_for_named_seller, :update?
  end

  test "denies support for another seller's commission" do
    refute_policy_permits CommissionPolicy, commissions(:another_seller_commission), :support_for_named_seller, :update?
  end
end
