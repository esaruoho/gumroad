# frozen_string_literal: true

require "test_helper"

class Admin::Impersonators::UserPolicyTest < ActiveSupport::TestCase
  def context_for(admin)
    SellerContext.new(user: admin, seller: admin)
  end

  test "grants access when record is a regular user" do
    policy = Admin::Impersonators::UserPolicy.new(context_for(users(:admin_user)), users(:basic_user))
    assert policy.create?
  end

  test "denies access when user is deleted" do
    policy = Admin::Impersonators::UserPolicy.new(context_for(users(:admin_user)), users(:deleted_user))
    refute policy.create?
  end

  test "denies access when user is a team member" do
    admin = users(:admin_user)
    policy = Admin::Impersonators::UserPolicy.new(context_for(admin), admin)
    refute policy.create?
  end
end
