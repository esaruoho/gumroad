# frozen_string_literal: true

require "test_helper"

class Settings::TeamPresenter::MemberInfo::MembershipInfoTest < ActiveSupport::TestCase
  setup do
    @seller = users(:named_seller)
    @admin_user = users(:admin_for_named_seller)
    @admin_membership = team_memberships(:admin_for_named_seller_membership)
    @other_admin_user = users(:other_admin_for_named_seller)
    @other_admin_membership = team_memberships(:other_admin_for_named_seller_membership)
    @marketing_user = users(:marketing_for_named_seller)
    @marketing_membership = team_memberships(:marketing_for_named_seller_membership)
  end

  test "build_membership_info returns self membership info for admin viewing own row" do
    pundit_user = SellerContext.new(user: @admin_user, seller: @seller)
    info = Settings::TeamPresenter::MemberInfo.build_membership_info(pundit_user:, team_membership: @admin_membership)

    assert_equal({
                   type: "membership",
                   id: @admin_membership.external_id,
                   role: TeamMembership::ROLE_ADMIN,
                   name: @admin_user.display_name,
                   email: @admin_user.form_email,
                   avatar_url: @admin_user.avatar_url,
                   is_expired: false,
                   options: [
                     { id: "accountant", label: "Accountant" },
                     { id: "admin", label: "Admin" },
                     { id: "marketing", label: "Marketing" },
                     { id: "support", label: "Support" }
                   ],
                   leave_team_option: { id: "leave_team", label: "Leave team" }
                 }, info.to_hash)
  end

  test "build_membership_info returns other membership info with remove_from_team option" do
    pundit_user = SellerContext.new(user: @admin_user, seller: @seller)
    info = Settings::TeamPresenter::MemberInfo.build_membership_info(pundit_user:, team_membership: @other_admin_membership)

    assert_equal({
                   type: "membership",
                   id: @other_admin_membership.external_id,
                   role: TeamMembership::ROLE_ADMIN,
                   name: @other_admin_user.display_name,
                   email: @other_admin_user.form_email,
                   avatar_url: @other_admin_user.avatar_url,
                   is_expired: false,
                   options: [
                     { id: "accountant", label: "Accountant" },
                     { id: "admin", label: "Admin" },
                     { id: "marketing", label: "Marketing" },
                     { id: "support", label: "Support" },
                     { id: "remove_from_team", label: "Remove from team" }
                   ],
                   leave_team_option: nil
                 }, info.to_hash)
  end

  test "build_membership_info includes wip role in options for other membership with marketing role" do
    @other_admin_membership.update_attribute(:role, TeamMembership::ROLE_MARKETING)
    pundit_user = SellerContext.new(user: @admin_user, seller: @seller)

    info = Settings::TeamPresenter::MemberInfo.build_membership_info(pundit_user:, team_membership: @other_admin_membership)

    assert_equal(
      [
        { id: "accountant", label: "Accountant" },
        { id: "admin", label: "Admin" },
        { id: "marketing", label: "Marketing" },
        { id: "support", label: "Support" },
        { id: "remove_from_team", label: "Remove from team" }
      ],
      info.to_hash[:options]
    )
  end

  test "build_membership_info for user with marketing role includes only current role" do
    pundit_user = SellerContext.new(user: @marketing_user, seller: @seller)

    info = Settings::TeamPresenter::MemberInfo.build_membership_info(pundit_user:, team_membership: @marketing_membership)

    assert_equal({
                   type: "membership",
                   id: @marketing_membership.external_id,
                   role: TeamMembership::ROLE_MARKETING,
                   name: @marketing_user.display_name,
                   email: @marketing_user.form_email,
                   avatar_url: @marketing_user.avatar_url,
                   is_expired: false,
                   options: [
                     { id: "marketing", label: "Marketing" }
                   ],
                   leave_team_option: { id: "leave_team", label: "Leave team" }
                 }, info.to_hash)
  end
end
