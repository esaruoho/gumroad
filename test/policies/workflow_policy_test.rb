# frozen_string_literal: true

require "test_helper"

class WorkflowPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  READ_ACTIONS = %i[index?].freeze
  WRITE_ACTIONS = %i[
    create? new? edit? update? create_post_and_rule?
    create_and_publish_post_and_rule? delete? destroy? save_installments?
  ].freeze

  # index? — all roles permitted
  test "index? grants access to owner" do
    assert_policy_permits WorkflowPolicy, Workflow, :named_seller, *READ_ACTIONS
  end

  test "index? grants access to accountant" do
    assert_policy_permits WorkflowPolicy, Workflow, :accountant_for_named_seller, *READ_ACTIONS
  end

  test "index? grants access to admin" do
    assert_policy_permits WorkflowPolicy, Workflow, :admin_for_named_seller, *READ_ACTIONS
  end

  test "index? grants access to marketing" do
    assert_policy_permits WorkflowPolicy, Workflow, :marketing_for_named_seller, *READ_ACTIONS
  end

  test "index? grants access to support" do
    assert_policy_permits WorkflowPolicy, Workflow, :support_for_named_seller, *READ_ACTIONS
  end

  # write actions — owner + admin + marketing only
  test "write actions grant access to owner" do
    assert_policy_permits WorkflowPolicy, Workflow, :named_seller, *WRITE_ACTIONS
  end

  test "write actions deny access to accountant" do
    refute_policy_permits WorkflowPolicy, Workflow, :accountant_for_named_seller, *WRITE_ACTIONS
  end

  test "write actions grant access to admin" do
    assert_policy_permits WorkflowPolicy, Workflow, :admin_for_named_seller, *WRITE_ACTIONS
  end

  test "write actions grant access to marketing" do
    assert_policy_permits WorkflowPolicy, Workflow, :marketing_for_named_seller, *WRITE_ACTIONS
  end

  test "write actions deny access to support" do
    refute_policy_permits WorkflowPolicy, Workflow, :support_for_named_seller, *WRITE_ACTIONS
  end
end
