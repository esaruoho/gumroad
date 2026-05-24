# frozen_string_literal: true

require "test_helper"

class LinkPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  INDEX_ACTIONS = %i[index?].freeze
  OWNER_ADMIN_MARKETING_ACTIONS = %i[new? create? show? unpublish? publish? destroy? release_preorder?].freeze
  EDIT_UPDATE_ACTIONS = %i[edit? update?].freeze

  # --- index? : all roles granted ---

  test "index? grants access to owner" do
    assert_policy_permits LinkPolicy, Link, :named_seller, *INDEX_ACTIONS
  end

  test "index? grants access to accountant" do
    assert_policy_permits LinkPolicy, Link, :accountant_for_named_seller, *INDEX_ACTIONS
  end

  test "index? grants access to admin" do
    assert_policy_permits LinkPolicy, Link, :admin_for_named_seller, *INDEX_ACTIONS
  end

  test "index? grants access to marketing" do
    assert_policy_permits LinkPolicy, Link, :marketing_for_named_seller, *INDEX_ACTIONS
  end

  test "index? grants access to support" do
    assert_policy_permits LinkPolicy, Link, :support_for_named_seller, *INDEX_ACTIONS
  end

  # --- new?/create?/show?/unpublish?/publish?/destroy?/release_preorder? ---

  test "owner-admin-marketing actions grant access to owner" do
    assert_policy_permits LinkPolicy, Link, :named_seller, *OWNER_ADMIN_MARKETING_ACTIONS
  end

  test "owner-admin-marketing actions deny accountant" do
    refute_policy_permits LinkPolicy, Link, :accountant_for_named_seller, *OWNER_ADMIN_MARKETING_ACTIONS
  end

  test "owner-admin-marketing actions grant admin" do
    assert_policy_permits LinkPolicy, Link, :admin_for_named_seller, *OWNER_ADMIN_MARKETING_ACTIONS
  end

  test "owner-admin-marketing actions grant marketing" do
    assert_policy_permits LinkPolicy, Link, :marketing_for_named_seller, *OWNER_ADMIN_MARKETING_ACTIONS
  end

  test "owner-admin-marketing actions deny support" do
    refute_policy_permits LinkPolicy, Link, :support_for_named_seller, *OWNER_ADMIN_MARKETING_ACTIONS
  end

  # --- edit? : team member (Gumroad staff) granted ---

  test "edit? grants access to gumroad team member" do
    team_member = users(:admin_user)
    ctx = SellerContext.new(user: team_member, seller: team_member)
    assert LinkPolicy.new(ctx, Link).edit?, "expected LinkPolicy#edit? to permit gumroad team member"
  end

  # --- edit?/update? when product belongs to seller ---

  test "edit?/update? grants access to a collaborator on the product" do
    collaborator_user = users(:collaborating_user)
    ctx = SellerContext.new(user: collaborator_user, seller: collaborator_user)
    EDIT_UPDATE_ACTIONS.each do |action|
      assert LinkPolicy.new(ctx, links(:named_seller_product)).public_send(action),
             "expected LinkPolicy##{action} to permit collaborator"
    end
  end

  test "edit?/update? grants access to owner for own product" do
    assert_policy_permits LinkPolicy, links(:named_seller_product), :named_seller, *EDIT_UPDATE_ACTIONS
  end

  test "edit?/update? denies accountant for owner's product" do
    refute_policy_permits LinkPolicy, links(:named_seller_product), :accountant_for_named_seller, *EDIT_UPDATE_ACTIONS
  end

  test "edit?/update? grants admin for owner's product" do
    assert_policy_permits LinkPolicy, links(:named_seller_product), :admin_for_named_seller, *EDIT_UPDATE_ACTIONS
  end

  test "edit?/update? grants marketing for owner's product" do
    assert_policy_permits LinkPolicy, links(:named_seller_product), :marketing_for_named_seller, *EDIT_UPDATE_ACTIONS
  end

  test "edit?/update? denies support for owner's product" do
    refute_policy_permits LinkPolicy, links(:named_seller_product), :support_for_named_seller, *EDIT_UPDATE_ACTIONS
  end

  # --- edit?/update? when product belongs to other user ---

  test "edit?/update? denies owner for product belonging to other user" do
    refute_policy_permits LinkPolicy, links(:basic_user_product), :named_seller, *EDIT_UPDATE_ACTIONS
  end

  test "edit?/update? denies accountant for product belonging to other user" do
    refute_policy_permits LinkPolicy, links(:basic_user_product), :accountant_for_named_seller, *EDIT_UPDATE_ACTIONS
  end

  test "edit?/update? denies admin for product belonging to other user" do
    refute_policy_permits LinkPolicy, links(:basic_user_product), :admin_for_named_seller, *EDIT_UPDATE_ACTIONS
  end

  test "edit?/update? denies marketing for product belonging to other user" do
    refute_policy_permits LinkPolicy, links(:basic_user_product), :marketing_for_named_seller, *EDIT_UPDATE_ACTIONS
  end

  test "edit?/update? denies support for product belonging to other user" do
    refute_policy_permits LinkPolicy, links(:basic_user_product), :support_for_named_seller, *EDIT_UPDATE_ACTIONS
  end
end
