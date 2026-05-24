# frozen_string_literal: true

require "test_helper"

class CollaboratorPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  CLASS_ACTIONS = %i[index? new? create?].freeze

  # ---- class-level (record is Collaborator class) ----

  test "grants class actions to owner and admin" do
    assert_policy_permits CollaboratorPolicy, Collaborator, :named_seller, *CLASS_ACTIONS
    assert_policy_permits CollaboratorPolicy, Collaborator, :admin_for_named_seller, *CLASS_ACTIONS
  end

  test "denies class actions to accountant, marketing, support" do
    refute_policy_permits CollaboratorPolicy, Collaborator, :accountant_for_named_seller, *CLASS_ACTIONS
    refute_policy_permits CollaboratorPolicy, Collaborator, :marketing_for_named_seller, *CLASS_ACTIONS
    refute_policy_permits CollaboratorPolicy, Collaborator, :support_for_named_seller, *CLASS_ACTIONS
  end

  # ---- edit?/update? on collaboration initiated by seller ----

  test "grants edit?/update? on own collaboration to owner and admin" do
    record = affiliates(:collaborator_for_named_seller_product)
    assert_policy_permits CollaboratorPolicy, record, :named_seller, :edit?, :update?
    assert_policy_permits CollaboratorPolicy, record, :admin_for_named_seller, :edit?, :update?
  end

  test "denies edit?/update? on own collaboration to accountant, marketing, support" do
    record = affiliates(:collaborator_for_named_seller_product)
    refute_policy_permits CollaboratorPolicy, record, :accountant_for_named_seller, :edit?, :update?
    refute_policy_permits CollaboratorPolicy, record, :marketing_for_named_seller, :edit?, :update?
    refute_policy_permits CollaboratorPolicy, record, :support_for_named_seller, :edit?, :update?
  end

  # ---- edit?/update? denied for collaboration where seller is affiliate ----

  test "denies edit?/update? on collaboration adding seller to all roles" do
    record = affiliates(:collaborator_adding_named_seller)
    refute_policy_permits CollaboratorPolicy, record, :named_seller, :edit?, :update?
    refute_policy_permits CollaboratorPolicy, record, :admin_for_named_seller, :edit?, :update?
    refute_policy_permits CollaboratorPolicy, record, :accountant_for_named_seller, :edit?, :update?
    refute_policy_permits CollaboratorPolicy, record, :marketing_for_named_seller, :edit?, :update?
    refute_policy_permits CollaboratorPolicy, record, :support_for_named_seller, :edit?, :update?
  end

  test "denies edit?/update? on unrelated collaboration to all roles" do
    record = affiliates(:collaborator_between_other_people)
    refute_policy_permits CollaboratorPolicy, record, :named_seller, :edit?, :update?
    refute_policy_permits CollaboratorPolicy, record, :admin_for_named_seller, :edit?, :update?
    refute_policy_permits CollaboratorPolicy, record, :accountant_for_named_seller, :edit?, :update?
    refute_policy_permits CollaboratorPolicy, record, :marketing_for_named_seller, :edit?, :update?
    refute_policy_permits CollaboratorPolicy, record, :support_for_named_seller, :edit?, :update?
  end

  # ---- destroy? grants for own + adding-seller collaborations ----

  test "grants destroy? on own collaboration to owner and admin" do
    record = affiliates(:collaborator_for_named_seller_product)
    assert_policy_permits CollaboratorPolicy, record, :named_seller, :destroy?
    assert_policy_permits CollaboratorPolicy, record, :admin_for_named_seller, :destroy?
  end

  test "denies destroy? on own collaboration to non-admin roles" do
    record = affiliates(:collaborator_for_named_seller_product)
    refute_policy_permits CollaboratorPolicy, record, :accountant_for_named_seller, :destroy?
    refute_policy_permits CollaboratorPolicy, record, :marketing_for_named_seller, :destroy?
    refute_policy_permits CollaboratorPolicy, record, :support_for_named_seller, :destroy?
  end

  test "grants destroy? on collaboration adding seller to owner and admin" do
    record = affiliates(:collaborator_adding_named_seller)
    assert_policy_permits CollaboratorPolicy, record, :named_seller, :destroy?
    assert_policy_permits CollaboratorPolicy, record, :admin_for_named_seller, :destroy?
  end

  test "denies destroy? on collaboration adding seller to non-admin roles" do
    record = affiliates(:collaborator_adding_named_seller)
    refute_policy_permits CollaboratorPolicy, record, :accountant_for_named_seller, :destroy?
    refute_policy_permits CollaboratorPolicy, record, :marketing_for_named_seller, :destroy?
    refute_policy_permits CollaboratorPolicy, record, :support_for_named_seller, :destroy?
  end

  test "denies destroy? on unrelated collaboration to all roles" do
    record = affiliates(:collaborator_between_other_people)
    refute_policy_permits CollaboratorPolicy, record, :named_seller, :destroy?
    refute_policy_permits CollaboratorPolicy, record, :admin_for_named_seller, :destroy?
    refute_policy_permits CollaboratorPolicy, record, :accountant_for_named_seller, :destroy?
    refute_policy_permits CollaboratorPolicy, record, :marketing_for_named_seller, :destroy?
    refute_policy_permits CollaboratorPolicy, record, :support_for_named_seller, :destroy?
  end
end
