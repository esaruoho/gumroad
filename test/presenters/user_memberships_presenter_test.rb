# frozen_string_literal: true

require "test_helper"

class UserMembershipsPresenterTest < ActiveSupport::TestCase
  setup do
    @user = users(:ump_user)
    @seller_one = users(:ump_seller_one)
    @seller_two = users(:ump_seller_two)
    @seller_three = users(:ump_seller_three)
    @team_membership_owner = team_memberships(:ump_user_owner)
    @team_membership_one = team_memberships(:ump_user_in_seller_one)
    @team_membership_two = team_memberships(:ump_user_in_seller_two)
    @team_membership_three = team_memberships(:ump_other_user_in_seller_three)
    @pundit_user = SellerContext.new(user: @user, seller: @seller_one)
  end

  test "returns all memberships that belong to the user, ordered" do
    @team_membership_one.update!(last_accessed_at: Time.current)

    props = UserMembershipsPresenter.new(pundit_user: @pundit_user).props
    assert_equal 3, props.length
    assert_equal expected_memberships(@team_membership_one, has_some_read_only_access: false, is_selected: true), props[0]
    assert_equal expected_memberships(@team_membership_two, has_some_read_only_access: false), props[1]
    assert_equal expected_memberships(@team_membership_owner, has_some_read_only_access: false), props[2]
  end

  test "returns correct has_some_read_only_access when role is marketing" do
    @team_membership_one.update!(
      last_accessed_at: Time.current,
      role: TeamMembership::ROLE_MARKETING
    )

    props = UserMembershipsPresenter.new(pundit_user: @pundit_user).props
    assert_equal expected_memberships(@team_membership_one, has_some_read_only_access: true, is_selected: true), props[0]
  end

  test "doesn't include deleted membership" do
    @team_membership_one.update!(last_accessed_at: Time.current)
    @team_membership_two.update_as_deleted!

    props = UserMembershipsPresenter.new(pundit_user: @pundit_user).props
    assert_equal 2, props.length
    assert_equal expected_memberships(@team_membership_one, has_some_read_only_access: false, is_selected: true), props[0]
    assert_equal expected_memberships(@team_membership_owner, has_some_read_only_access: false), props[1]
  end

  test "notifies error tracker when owner membership is missing with other memberships present" do
    @team_membership_owner.destroy!

    notify_calls = []
    original = ErrorNotifier.method(:notify)
    ErrorNotifier.define_singleton_method(:notify) { |msg| notify_calls << msg }
    begin
      props = UserMembershipsPresenter.new(pundit_user: @pundit_user).props
      assert_equal [], props
    ensure
      ErrorNotifier.singleton_class.send(:remove_method, :notify) rescue nil
      ErrorNotifier.define_singleton_method(:notify, original)
    end

    assert_equal 1, notify_calls.size
    assert_equal "Missing owner team membership for user #{@user.id}", notify_calls.first
  end

  test "doesn't notify when owner membership is missing and there are no other memberships" do
    @team_membership_owner.destroy!
    @user.user_memberships.delete_all

    notify_calls = []
    original = ErrorNotifier.method(:notify)
    ErrorNotifier.define_singleton_method(:notify) { |msg| notify_calls << msg }
    begin
      props = UserMembershipsPresenter.new(pundit_user: @pundit_user).props
      assert_equal [], props
    ensure
      ErrorNotifier.singleton_class.send(:remove_method, :notify) rescue nil
      ErrorNotifier.define_singleton_method(:notify, original)
    end

    assert_empty notify_calls
  end

  private
    def expected_memberships(team_membership, has_some_read_only_access:, is_selected: false)
      seller = team_membership.seller
      {
        id: team_membership.external_id,
        seller_name: seller.display_name(prefer_email_over_default_username: true),
        seller_avatar_url: seller.avatar_url,
        has_some_read_only_access:,
        is_selected:
      }
    end
end
