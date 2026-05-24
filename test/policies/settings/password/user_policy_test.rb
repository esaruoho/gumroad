# frozen_string_literal: true

require "test_helper"

class Settings::Password::UserPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  ACTIONS = %i[show? update?].freeze

  test "grants access to owner" do
    assert_policy_permits Settings::Password::UserPolicy, users(:named_seller), :named_seller, *ACTIONS
  end

  test "denies access to accountant" do
    refute_policy_permits Settings::Password::UserPolicy, users(:named_seller), :accountant_for_named_seller, *ACTIONS
  end

  test "denies access to admin" do
    refute_policy_permits Settings::Password::UserPolicy, users(:named_seller), :admin_for_named_seller, *ACTIONS
  end

  test "denies access to marketing" do
    refute_policy_permits Settings::Password::UserPolicy, users(:named_seller), :marketing_for_named_seller, *ACTIONS
  end

  test "denies access to support" do
    refute_policy_permits Settings::Password::UserPolicy, users(:named_seller), :support_for_named_seller, *ACTIONS
  end
end
