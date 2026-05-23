# frozen_string_literal: true

require "test_helper"

class Settings::Team::TeamInvitationPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  WRITE_ACTIONS = %i[create? update? destroy? restore? resend_invitation?].freeze
  ACCEPT_ACTIONS = %i[accept?].freeze

  # write actions — owner + admin only
  test "write actions grant access to owner" do
    assert_policy_permits Settings::Team::TeamInvitationPolicy, users(:named_seller), :named_seller, *WRITE_ACTIONS
  end

  test "write actions deny accountant" do
    refute_policy_permits Settings::Team::TeamInvitationPolicy, users(:named_seller), :accountant_for_named_seller, *WRITE_ACTIONS
  end

  test "write actions grant access to admin" do
    assert_policy_permits Settings::Team::TeamInvitationPolicy, users(:named_seller), :admin_for_named_seller, *WRITE_ACTIONS
  end

  test "write actions deny marketing" do
    refute_policy_permits Settings::Team::TeamInvitationPolicy, users(:named_seller), :marketing_for_named_seller, *WRITE_ACTIONS
  end

  test "write actions deny support" do
    refute_policy_permits Settings::Team::TeamInvitationPolicy, users(:named_seller), :support_for_named_seller, *WRITE_ACTIONS
  end

  # accept? — owner only
  test "accept? grants access to owner" do
    assert_policy_permits Settings::Team::TeamInvitationPolicy, users(:named_seller), :named_seller, *ACCEPT_ACTIONS
  end

  test "accept? denies accountant" do
    refute_policy_permits Settings::Team::TeamInvitationPolicy, users(:named_seller), :accountant_for_named_seller, *ACCEPT_ACTIONS
  end

  test "accept? denies admin" do
    refute_policy_permits Settings::Team::TeamInvitationPolicy, users(:named_seller), :admin_for_named_seller, *ACCEPT_ACTIONS
  end

  test "accept? denies marketing" do
    refute_policy_permits Settings::Team::TeamInvitationPolicy, users(:named_seller), :marketing_for_named_seller, *ACCEPT_ACTIONS
  end

  test "accept? denies support" do
    refute_policy_permits Settings::Team::TeamInvitationPolicy, users(:named_seller), :support_for_named_seller, *ACCEPT_ACTIONS
  end
end
