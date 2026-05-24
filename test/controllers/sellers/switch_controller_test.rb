# frozen_string_literal: true

require "test_helper"

class Sellers::SwitchControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @user = users(:purchaser)
    @seller = users(:named_seller)
    boot_controller_test!
    sign_in @user
    @request.cookie_jar.encrypted[:current_seller_id] = nil
    unless TeamMembership.where(user: @user, seller: @user, role: TeamMembership::ROLE_OWNER).exists?
      TeamMembership.create!(user: @user, seller: @user, role: TeamMembership::ROLE_OWNER)
    end
  end

  teardown { restore_protect_against_forgery! }

  test "POST create with invalid team membership record does not set cookie" do
    post :create, params: { team_membership_id: "foo" }
    assert_nil cookies.encrypted[:current_seller_id]
    assert_response :no_content
  end

  test "POST create sets cookie and updates last_accessed_at" do
    tm = TeamMembership.create!(user: @user, seller: @seller, role: TeamMembership::ROLE_ADMIN)
    post :create, params: { team_membership_id: tm.external_id.to_s }
    assert_equal @seller.id, cookies.encrypted[:current_seller_id]
    assert_in_delta Time.current, tm.reload.last_accessed_at, 5
    assert_response :no_content
  end

  test "POST create with deleted team membership doesn't set cookie" do
    tm = TeamMembership.create!(user: @user, seller: @seller, role: TeamMembership::ROLE_ADMIN)
    tm.update_as_deleted!
    post :create, params: { team_membership_id: tm.external_id.to_s }
    assert_nil cookies.encrypted[:current_seller_id]
    assert_response :no_content
  end
end
