# frozen_string_literal: true

require "test_helper"

class Settings::AuthorizedApplications::OauthApplicationPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  ACTIONS = %i[index? create? edit? update? destroy?].freeze

  test "grants access to owner" do
    assert_policy_permits Settings::AuthorizedApplications::OauthApplicationPolicy, users(:named_seller), :named_seller, *ACTIONS
  end

  test "denies access to accountant" do
    refute_policy_permits Settings::AuthorizedApplications::OauthApplicationPolicy, users(:named_seller), :accountant_for_named_seller, *ACTIONS
  end

  test "grants access to admin" do
    assert_policy_permits Settings::AuthorizedApplications::OauthApplicationPolicy, users(:named_seller), :admin_for_named_seller, *ACTIONS
  end

  test "denies access to marketing" do
    refute_policy_permits Settings::AuthorizedApplications::OauthApplicationPolicy, users(:named_seller), :marketing_for_named_seller, *ACTIONS
  end

  test "denies access to support" do
    refute_policy_permits Settings::AuthorizedApplications::OauthApplicationPolicy, users(:named_seller), :support_for_named_seller, *ACTIONS
  end
end
