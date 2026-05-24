# frozen_string_literal: true

require "test_helper"

class PurchasePolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  ACTIONS = %i[index? archive? unarchive? delete?].freeze

  test "grants access to owner" do
    assert_policy_permits PurchasePolicy, Purchase, :named_seller, *ACTIONS
  end

  test "denies access to accountant" do
    refute_policy_permits PurchasePolicy, Purchase, :accountant_for_named_seller, *ACTIONS
  end

  test "denies access to admin" do
    refute_policy_permits PurchasePolicy, Purchase, :admin_for_named_seller, *ACTIONS
  end

  test "denies access to marketing" do
    refute_policy_permits PurchasePolicy, Purchase, :marketing_for_named_seller, *ACTIONS
  end

  test "denies access to support" do
    refute_policy_permits PurchasePolicy, Purchase, :support_for_named_seller, *ACTIONS
  end
end
