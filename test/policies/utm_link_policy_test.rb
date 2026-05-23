# frozen_string_literal: true

require "test_helper"

class UtmLinkPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  INDEX_ACTIONS = %i[index?].freeze
  WRITE_ACTIONS = %i[new? create? edit? update? destroy?].freeze

  setup do
    Feature.activate_user(:utm_links, users(:named_seller))
  end

  teardown do
    Feature.deactivate_user(:utm_links, users(:named_seller))
  end

  # index? — all roles permitted
  test "index? grants access to owner" do
    assert_policy_permits UtmLinkPolicy, :utm_link, :named_seller, *INDEX_ACTIONS
  end

  test "index? grants access to accountant" do
    assert_policy_permits UtmLinkPolicy, :utm_link, :accountant_for_named_seller, *INDEX_ACTIONS
  end

  test "index? grants access to admin" do
    assert_policy_permits UtmLinkPolicy, :utm_link, :admin_for_named_seller, *INDEX_ACTIONS
  end

  test "index? grants access to marketing" do
    assert_policy_permits UtmLinkPolicy, :utm_link, :marketing_for_named_seller, *INDEX_ACTIONS
  end

  test "index? grants access to support" do
    assert_policy_permits UtmLinkPolicy, :utm_link, :support_for_named_seller, *INDEX_ACTIONS
  end

  # write actions — admin + marketing only
  test "write actions grant access to admin" do
    assert_policy_permits UtmLinkPolicy, :utm_link, :admin_for_named_seller, *WRITE_ACTIONS
  end

  test "write actions grant access to marketing" do
    assert_policy_permits UtmLinkPolicy, :utm_link, :marketing_for_named_seller, *WRITE_ACTIONS
  end

  test "write actions deny accountant" do
    refute_policy_permits UtmLinkPolicy, :utm_link, :accountant_for_named_seller, *WRITE_ACTIONS
  end

  test "write actions deny support" do
    refute_policy_permits UtmLinkPolicy, :utm_link, :support_for_named_seller, *WRITE_ACTIONS
  end
end
