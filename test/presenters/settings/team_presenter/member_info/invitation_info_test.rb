# frozen_string_literal: true

require "test_helper"

class Settings::TeamPresenter::MemberInfo::InvitationInfoTest < ActiveSupport::TestCase
  setup do
    @seller = users(:named_seller)
    @team_invitation = team_invitations(:named_seller_expired_admin_invitation)
    @email = @team_invitation.email
  end

  test "build_invitation_info returns correct info when admin user views an expired admin invitation" do
    user = users(:admin_for_named_seller)
    pundit_user = SellerContext.new(user:, seller: @seller)

    info = Settings::TeamPresenter::MemberInfo.build_invitation_info(pundit_user:, team_invitation: @team_invitation)

    assert_equal({
                   type: "invitation",
                   id: @team_invitation.external_id,
                   role: "admin",
                   name: "",
                   email: @email,
                   avatar_url: ActionController::Base.helpers.image_url("gumroad-default-avatar-5.png"),
                   is_expired: true,
                   options: [
                     { id: "accountant", label: "Accountant" },
                     { id: "admin", label: "Admin" },
                     { id: "marketing", label: "Marketing" },
                     { id: "support", label: "Support" },
                     { id: "resend_invitation", label: "Resend invitation" },
                     { id: "remove_from_team", label: "Remove from team" }
                   ],
                   leave_team_option: nil
                 }, info.to_hash)
  end

  test "build_invitation_info includes wip role in options when invitation has wip role" do
    user = users(:admin_for_named_seller)
    pundit_user = SellerContext.new(user:, seller: @seller)
    @team_invitation.update_attribute(:role, TeamMembership::ROLE_MARKETING)

    info = Settings::TeamPresenter::MemberInfo.build_invitation_info(pundit_user:, team_invitation: @team_invitation)

    assert_equal({
                   type: "invitation",
                   id: @team_invitation.external_id,
                   role: "marketing",
                   name: "",
                   email: @email,
                   avatar_url: ActionController::Base.helpers.image_url("gumroad-default-avatar-5.png"),
                   is_expired: true,
                   options: [
                     { id: "accountant", label: "Accountant" },
                     { id: "admin", label: "Admin" },
                     { id: "marketing", label: "Marketing" },
                     { id: "support", label: "Support" },
                     { id: "resend_invitation", label: "Resend invitation" },
                     { id: "remove_from_team", label: "Remove from team" }
                   ],
                   leave_team_option: nil
                 }, info.to_hash)
  end

  test "build_invitation_info includes only the current role when user signed in as marketing" do
    user = users(:marketing_for_named_seller)
    pundit_user = SellerContext.new(user:, seller: @seller)

    info = Settings::TeamPresenter::MemberInfo.build_invitation_info(pundit_user:, team_invitation: @team_invitation)

    assert_equal([{ id: "admin", label: "Admin" }], info.to_hash[:options])
  end
end
