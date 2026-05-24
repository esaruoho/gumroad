# frozen_string_literal: true

require "test_helper"

class DirectAffiliatePolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  READ_ACTIONS = %i[index? statistics?].freeze
  WRITE_ACTIONS = %i[create? update? destroy?].freeze

  # read actions — all roles permitted
  test "read actions grant access to owner" do
    assert_policy_permits DirectAffiliatePolicy, DirectAffiliate, :named_seller, *READ_ACTIONS
  end

  test "read actions grant access to accountant" do
    assert_policy_permits DirectAffiliatePolicy, DirectAffiliate, :accountant_for_named_seller, *READ_ACTIONS
  end

  test "read actions grant access to admin" do
    assert_policy_permits DirectAffiliatePolicy, DirectAffiliate, :admin_for_named_seller, *READ_ACTIONS
  end

  test "read actions grant access to marketing" do
    assert_policy_permits DirectAffiliatePolicy, DirectAffiliate, :marketing_for_named_seller, *READ_ACTIONS
  end

  test "read actions grant access to support" do
    assert_policy_permits DirectAffiliatePolicy, DirectAffiliate, :support_for_named_seller, *READ_ACTIONS
  end

  # write actions — owner + admin + marketing only
  test "write actions grant access to owner" do
    assert_policy_permits DirectAffiliatePolicy, DirectAffiliate, :named_seller, *WRITE_ACTIONS
  end

  test "write actions deny access to accountant" do
    refute_policy_permits DirectAffiliatePolicy, DirectAffiliate, :accountant_for_named_seller, *WRITE_ACTIONS
  end

  test "write actions grant access to admin" do
    assert_policy_permits DirectAffiliatePolicy, DirectAffiliate, :admin_for_named_seller, *WRITE_ACTIONS
  end

  test "write actions grant access to marketing" do
    assert_policy_permits DirectAffiliatePolicy, DirectAffiliate, :marketing_for_named_seller, *WRITE_ACTIONS
  end

  test "write actions deny access to support" do
    refute_policy_permits DirectAffiliatePolicy, DirectAffiliate, :support_for_named_seller, *WRITE_ACTIONS
  end
end
