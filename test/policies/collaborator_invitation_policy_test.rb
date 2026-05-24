# frozen_string_literal: true

require "test_helper"

class CollaboratorInvitationPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  ACTIONS = %i[accept? decline?].freeze

  test "grants access on invitation for seller to owner and admin" do
    record = collaborator_invitations(:invitation_for_named_seller)
    assert_policy_permits CollaboratorInvitationPolicy, record, :named_seller, *ACTIONS
    assert_policy_permits CollaboratorInvitationPolicy, record, :admin_for_named_seller, *ACTIONS
  end

  test "denies access on invitation for seller to non-admin roles" do
    record = collaborator_invitations(:invitation_for_named_seller)
    refute_policy_permits CollaboratorInvitationPolicy, record, :accountant_for_named_seller, *ACTIONS
    refute_policy_permits CollaboratorInvitationPolicy, record, :marketing_for_named_seller, *ACTIONS
    refute_policy_permits CollaboratorInvitationPolicy, record, :support_for_named_seller, *ACTIONS
  end

  test "denies access on invitation for another seller to all roles" do
    record = collaborator_invitations(:invitation_for_another_seller)
    refute_policy_permits CollaboratorInvitationPolicy, record, :named_seller, *ACTIONS
    refute_policy_permits CollaboratorInvitationPolicy, record, :admin_for_named_seller, *ACTIONS
    refute_policy_permits CollaboratorInvitationPolicy, record, :accountant_for_named_seller, *ACTIONS
    refute_policy_permits CollaboratorInvitationPolicy, record, :marketing_for_named_seller, *ACTIONS
    refute_policy_permits CollaboratorInvitationPolicy, record, :support_for_named_seller, *ACTIONS
  end
end
