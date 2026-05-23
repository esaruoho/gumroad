# frozen_string_literal: true

require "test_helper"

class Audience::PurchasePolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  INDEX_ACTIONS = %i[index?].freeze
  WRITE_ACTIONS = %i[update? refund? change_can_contact? cancel_preorder_by_seller? mark_as_shipped? manage_license?].freeze

  # ---- index? ----
  test "index? grants access to owner" do
    assert_policy_permits Audience::PurchasePolicy, Purchase, :named_seller, *INDEX_ACTIONS
  end

  test "index? grants access to accountant" do
    assert_policy_permits Audience::PurchasePolicy, Purchase, :accountant_for_named_seller, *INDEX_ACTIONS
  end

  test "index? grants access to admin" do
    assert_policy_permits Audience::PurchasePolicy, Purchase, :admin_for_named_seller, *INDEX_ACTIONS
  end

  test "index? grants access to marketing" do
    assert_policy_permits Audience::PurchasePolicy, Purchase, :marketing_for_named_seller, *INDEX_ACTIONS
  end

  test "index? grants access to support" do
    assert_policy_permits Audience::PurchasePolicy, Purchase, :support_for_named_seller, *INDEX_ACTIONS
  end

  # ---- update?/refund?/change_can_contact?/cancel_preorder_by_seller?/mark_as_shipped?/manage_license? ----
  test "write actions grant access to owner" do
    assert_policy_permits Audience::PurchasePolicy, Follower, :named_seller, *WRITE_ACTIONS
  end

  test "write actions deny access to accountant" do
    refute_policy_permits Audience::PurchasePolicy, Purchase, :accountant_for_named_seller, *WRITE_ACTIONS
  end

  test "write actions grant access to admin" do
    assert_policy_permits Audience::PurchasePolicy, Follower, :admin_for_named_seller, *WRITE_ACTIONS
  end

  test "write actions deny access to marketing" do
    refute_policy_permits Audience::PurchasePolicy, Follower, :marketing_for_named_seller, *WRITE_ACTIONS
  end

  test "write actions grant access to support" do
    assert_policy_permits Audience::PurchasePolicy, Purchase, :support_for_named_seller, *WRITE_ACTIONS
  end

  # ---- revoke_access? ----
  test "revoke_access? grants access to owner" do
    assert_policy_permits Audience::PurchasePolicy, purchases(:audience_purchase), :named_seller, :revoke_access?
  end

  test "revoke_access? denies access to accountant" do
    refute_policy_permits Audience::PurchasePolicy, Purchase, :accountant_for_named_seller, :revoke_access?
  end

  test "revoke_access? grants access to admin" do
    assert_policy_permits Audience::PurchasePolicy, purchases(:audience_purchase), :admin_for_named_seller, :revoke_access?
  end

  test "revoke_access? denies access to marketing" do
    refute_policy_permits Audience::PurchasePolicy, purchases(:audience_purchase), :marketing_for_named_seller, :revoke_access?
  end

  test "revoke_access? grants access to support" do
    assert_policy_permits Audience::PurchasePolicy, purchases(:audience_purchase), :support_for_named_seller, :revoke_access?
  end

  test "revoke_access? denies when access already revoked" do
    refute_policy_permits Audience::PurchasePolicy, purchases(:audience_revoked_purchase), :named_seller, :revoke_access?
  end

  test "revoke_access? denies when purchase is refunded" do
    purchase = purchases(:audience_purchase)
    purchase.update_columns(stripe_refunded: true)
    refute_policy_permits Audience::PurchasePolicy, purchase, :named_seller, :revoke_access?
  end

  test "revoke_access? denies when product is physical" do
    refute_policy_permits Audience::PurchasePolicy, purchases(:audience_physical_purchase), :named_seller, :revoke_access?
  end

  test "revoke_access? denies when purchase is subscription" do
    refute_policy_permits Audience::PurchasePolicy, purchases(:audience_membership_purchase), :named_seller, :revoke_access?
  end

  # ---- undo_revoke_access? ----
  test "undo_revoke_access? grants access to owner" do
    assert_policy_permits Audience::PurchasePolicy, purchases(:audience_revoked_purchase), :named_seller, :undo_revoke_access?
  end

  test "undo_revoke_access? denies access to accountant" do
    refute_policy_permits Audience::PurchasePolicy, Purchase, :accountant_for_named_seller, :undo_revoke_access?
  end

  test "undo_revoke_access? grants access to admin" do
    assert_policy_permits Audience::PurchasePolicy, purchases(:audience_revoked_purchase), :admin_for_named_seller, :undo_revoke_access?
  end

  test "undo_revoke_access? denies access to marketing" do
    refute_policy_permits Audience::PurchasePolicy, purchases(:audience_revoked_purchase), :marketing_for_named_seller, :undo_revoke_access?
  end

  test "undo_revoke_access? grants access to support" do
    assert_policy_permits Audience::PurchasePolicy, Purchase, :support_for_named_seller, :undo_revoke_access?
  end

  test "undo_revoke_access? denies when access has not been revoked" do
    refute_policy_permits Audience::PurchasePolicy, purchases(:audience_purchase), :named_seller, :undo_revoke_access?
  end
end
