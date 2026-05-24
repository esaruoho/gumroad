# frozen_string_literal: true

require "test_helper"

class Settings::TeamPresenterTest < ActiveSupport::TestCase
  def pundit_user_for(user)
    SellerContext.new(user:, seller: user)
  end

  test "initialize assigns the pundit_user" do
    pu = pundit_user_for(users(:another_seller))
    presenter = Settings::TeamPresenter.new(pundit_user: pu)
    assert_equal pu, presenter.pundit_user
  end

  test "#member_infos returns owner-only when seller has no other members" do
    # another_seller has only the owner self-membership and no invitations.
    pu = pundit_user_for(users(:another_seller))
    member_infos = Settings::TeamPresenter.new(pundit_user: pu).member_infos

    assert_equal 1, member_infos.count
    assert_equal Settings::TeamPresenter::MemberInfo::OwnerInfo, member_infos.first.class
  end

  test "#member_infos returns owner + active membership + active invitation" do
    seller = users(:team_presenter_seller)
    pu = pundit_user_for(seller)
    member_infos = Settings::TeamPresenter.new(pundit_user: pu).member_infos

    assert_equal 3, member_infos.count
    assert_equal Settings::TeamPresenter::MemberInfo::OwnerInfo, member_infos.first.class

    membership_info = member_infos.second
    assert_equal Settings::TeamPresenter::MemberInfo::MembershipInfo, membership_info.class
    expected_membership = team_memberships(:team_presenter_active_membership)
    assert_equal expected_membership.external_id, membership_info.to_hash[:id]

    invitation_info = member_infos.third
    assert_equal Settings::TeamPresenter::MemberInfo::InvitationInfo, invitation_info.class
    expected_invitation = team_invitations(:team_presenter_active_invitation)
    assert_equal expected_invitation.external_id, invitation_info.to_hash[:id]
  end
end
