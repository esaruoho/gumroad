# frozen_string_literal: true

require "test_helper"

class Settings::Payments::UserPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  SHOW_ACTIONS = %i[show?].freeze
  WRITE_ACTIONS = %i[update? set_country? verify_document? verify_identity? remove_credit_card?].freeze
  CONNECT_ACTIONS = %i[paypal_connect? stripe_connect?].freeze

  # show? — owner + admin only
  test "show? grants access to owner" do
    assert_policy_permits Settings::Payments::UserPolicy, users(:named_seller), :named_seller, *SHOW_ACTIONS
  end

  test "show? denies access to accountant" do
    refute_policy_permits Settings::Payments::UserPolicy, users(:named_seller), :accountant_for_named_seller, *SHOW_ACTIONS
  end

  test "show? grants access to admin" do
    assert_policy_permits Settings::Payments::UserPolicy, users(:named_seller), :admin_for_named_seller, *SHOW_ACTIONS
  end

  test "show? denies access to marketing" do
    refute_policy_permits Settings::Payments::UserPolicy, users(:named_seller), :marketing_for_named_seller, *SHOW_ACTIONS
  end

  test "show? denies access to support" do
    refute_policy_permits Settings::Payments::UserPolicy, users(:named_seller), :support_for_named_seller, *SHOW_ACTIONS
  end

  # write actions — only owner against own record
  test "write actions grant access to owner against own record" do
    assert_policy_permits Settings::Payments::UserPolicy, users(:named_seller), :named_seller, *WRITE_ACTIONS
  end

  test "write actions deny access to owner when record is a different user" do
    refute_policy_permits Settings::Payments::UserPolicy, users(:basic_user), :named_seller, *WRITE_ACTIONS
  end

  test "write actions deny access to admin" do
    refute_policy_permits Settings::Payments::UserPolicy, users(:named_seller), :admin_for_named_seller, *WRITE_ACTIONS
  end

  test "write actions deny access to marketing" do
    refute_policy_permits Settings::Payments::UserPolicy, users(:named_seller), :marketing_for_named_seller, *WRITE_ACTIONS
  end

  test "write actions deny access to accountant" do
    refute_policy_permits Settings::Payments::UserPolicy, users(:named_seller), :accountant_for_named_seller, *WRITE_ACTIONS
  end

  test "write actions deny access to support" do
    refute_policy_permits Settings::Payments::UserPolicy, users(:named_seller), :support_for_named_seller, *WRITE_ACTIONS
  end

  # paypal_connect?, stripe_connect? — owner only
  test "connect actions grant access to owner" do
    assert_policy_permits Settings::Payments::UserPolicy, users(:named_seller), :named_seller, *CONNECT_ACTIONS
  end

  test "connect actions deny access to accountant" do
    refute_policy_permits Settings::Payments::UserPolicy, users(:named_seller), :accountant_for_named_seller, *CONNECT_ACTIONS
  end

  test "connect actions deny access to admin" do
    refute_policy_permits Settings::Payments::UserPolicy, users(:named_seller), :admin_for_named_seller, *CONNECT_ACTIONS
  end

  test "connect actions deny access to marketing" do
    refute_policy_permits Settings::Payments::UserPolicy, users(:named_seller), :marketing_for_named_seller, *CONNECT_ACTIONS
  end

  test "connect actions deny access to support" do
    refute_policy_permits Settings::Payments::UserPolicy, users(:named_seller), :support_for_named_seller, *CONNECT_ACTIONS
  end
end
