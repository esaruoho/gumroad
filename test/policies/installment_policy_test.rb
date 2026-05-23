# frozen_string_literal: true

require "test_helper"

class InstallmentPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  READ_ACTIONS = %i[index? preview?].freeze
  WRITE_ACTIONS = %i[
    new? edit? create? update? destroy? publish? schedule? delete?
    redirect_from_purchase_id? updated_recipient_count?
  ].freeze
  SEND_ACTIONS = %i[send_for_purchase?].freeze

  # read actions — all roles permitted
  test "read actions grant access to owner" do
    assert_policy_permits InstallmentPolicy, Installment, :named_seller, *READ_ACTIONS
  end

  test "read actions grant access to accountant" do
    assert_policy_permits InstallmentPolicy, Installment, :accountant_for_named_seller, *READ_ACTIONS
  end

  test "read actions grant access to admin" do
    assert_policy_permits InstallmentPolicy, Installment, :admin_for_named_seller, *READ_ACTIONS
  end

  test "read actions grant access to marketing" do
    assert_policy_permits InstallmentPolicy, Installment, :marketing_for_named_seller, *READ_ACTIONS
  end

  test "read actions grant access to support" do
    assert_policy_permits InstallmentPolicy, Installment, :support_for_named_seller, *READ_ACTIONS
  end

  # write actions — owner + admin + marketing only
  test "write actions grant access to owner" do
    assert_policy_permits InstallmentPolicy, Installment, :named_seller, *WRITE_ACTIONS
  end

  test "write actions deny access to accountant" do
    refute_policy_permits InstallmentPolicy, Installment, :accountant_for_named_seller, *WRITE_ACTIONS
  end

  test "write actions grant access to admin" do
    assert_policy_permits InstallmentPolicy, Installment, :admin_for_named_seller, *WRITE_ACTIONS
  end

  test "write actions grant access to marketing" do
    assert_policy_permits InstallmentPolicy, Installment, :marketing_for_named_seller, *WRITE_ACTIONS
  end

  test "write actions deny access to support" do
    refute_policy_permits InstallmentPolicy, Installment, :support_for_named_seller, *WRITE_ACTIONS
  end

  # send_for_purchase? — owner + admin + marketing + support, denies accountant
  test "send_for_purchase? grants access to owner" do
    assert_policy_permits InstallmentPolicy, Installment, :named_seller, *SEND_ACTIONS
  end

  test "send_for_purchase? denies access to accountant" do
    refute_policy_permits InstallmentPolicy, Installment, :accountant_for_named_seller, *SEND_ACTIONS
  end

  test "send_for_purchase? grants access to admin" do
    assert_policy_permits InstallmentPolicy, Installment, :admin_for_named_seller, *SEND_ACTIONS
  end

  test "send_for_purchase? grants access to marketing" do
    assert_policy_permits InstallmentPolicy, Installment, :marketing_for_named_seller, *SEND_ACTIONS
  end

  test "send_for_purchase? grants access to support" do
    assert_policy_permits InstallmentPolicy, Installment, :support_for_named_seller, *SEND_ACTIONS
  end
end
