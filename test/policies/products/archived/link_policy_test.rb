# frozen_string_literal: true

require "test_helper"

class Products::Archived::LinkPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  test "index? — permits owner and all 4 roles" do
    [:named_seller, :accountant_for_named_seller, :admin_for_named_seller,
     :marketing_for_named_seller, :support_for_named_seller].each do |role|
      assert_policy_permits Products::Archived::LinkPolicy,
                            links(:named_seller_product), role, :index?
    end
  end

  test "create? on a not-archived product — permits owner, admin, marketing" do
    [:named_seller, :admin_for_named_seller, :marketing_for_named_seller].each do |role|
      assert_policy_permits Products::Archived::LinkPolicy,
                            links(:named_seller_product), role, :create?
    end
  end

  test "create? on a not-archived product — denies accountant and support" do
    [:accountant_for_named_seller, :support_for_named_seller].each do |role|
      refute_policy_permits Products::Archived::LinkPolicy,
                            links(:named_seller_product), role, :create?
    end
  end

  test "create? on an archived product — denies owner" do
    refute_policy_permits Products::Archived::LinkPolicy,
                          links(:named_seller_archived_product), :named_seller, :create?
  end

  test "destroy? on an archived product — permits owner, admin, marketing" do
    [:named_seller, :admin_for_named_seller, :marketing_for_named_seller].each do |role|
      assert_policy_permits Products::Archived::LinkPolicy,
                            links(:named_seller_archived_product), role, :destroy?
    end
  end

  test "destroy? on an archived product — denies accountant and support" do
    [:accountant_for_named_seller, :support_for_named_seller].each do |role|
      refute_policy_permits Products::Archived::LinkPolicy,
                            links(:named_seller_archived_product), role, :destroy?
    end
  end

  test "destroy? on a not-archived product — denies owner" do
    refute_policy_permits Products::Archived::LinkPolicy,
                          links(:named_seller_product), :named_seller, :destroy?
  end
end
