# frozen_string_literal: true

require "test_helper"

class Settings::Main::UserPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  SHOW_ACTIONS = %i[show?].freeze
  OWNER_ONLY_ACTIONS = %i[update? resend_confirmation_email? invalidate_active_sessions?].freeze

  # show? — owner + admin only
  test "show? grants access to owner" do
    assert_policy_permits Settings::Main::UserPolicy, users(:named_seller), :named_seller, *SHOW_ACTIONS
  end

  test "show? denies access to accountant" do
    refute_policy_permits Settings::Main::UserPolicy, users(:named_seller), :accountant_for_named_seller, *SHOW_ACTIONS
  end

  test "show? grants access to admin" do
    assert_policy_permits Settings::Main::UserPolicy, users(:named_seller), :admin_for_named_seller, *SHOW_ACTIONS
  end

  test "show? denies access to marketing" do
    refute_policy_permits Settings::Main::UserPolicy, users(:named_seller), :marketing_for_named_seller, *SHOW_ACTIONS
  end

  test "show? denies access to support" do
    refute_policy_permits Settings::Main::UserPolicy, users(:named_seller), :support_for_named_seller, *SHOW_ACTIONS
  end

  # owner-only actions
  test "owner-only actions grant access to owner" do
    assert_policy_permits Settings::Main::UserPolicy, users(:named_seller), :named_seller, *OWNER_ONLY_ACTIONS
  end

  test "owner-only actions deny admin" do
    refute_policy_permits Settings::Main::UserPolicy, users(:named_seller), :admin_for_named_seller, *OWNER_ONLY_ACTIONS
  end

  test "owner-only actions deny marketing" do
    refute_policy_permits Settings::Main::UserPolicy, users(:named_seller), :marketing_for_named_seller, *OWNER_ONLY_ACTIONS
  end
end
