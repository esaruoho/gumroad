# frozen_string_literal: true

require "test_helper"

class GumroadBlog::PostsPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  ROLE_FIXTURES = %i[
    named_seller
    accountant_for_named_seller
    admin_for_named_seller
    marketing_for_named_seller
    support_for_named_seller
  ].freeze

  # --- index? -------------------------------------------------------------

  test "index? grants access to all roles" do
    record = installments(:published_post)
    ROLE_FIXTURES.each do |role|
      assert_policy_permits GumroadBlog::PostsPolicy, record, role, :index?
    end
  end

  test "index? grants access to anonymous users" do
    assert GumroadBlog::PostsPolicy.new(SellerContext.logged_out, installments(:published_post)).index?
  end

  # --- show? : published post ---------------------------------------------

  test "show? grants access to all roles when post is published and shown" do
    record = installments(:published_post)
    ROLE_FIXTURES.each do |role|
      assert_policy_permits GumroadBlog::PostsPolicy, record, role, :show?
    end
  end

  test "show? grants access to anonymous users for published post" do
    assert GumroadBlog::PostsPolicy.new(SellerContext.logged_out, installments(:published_post)).show?
  end

  # --- show? : unpublished post -------------------------------------------

  test "show? grants access to seller's own team for unpublished post" do
    record = installments(:unpublished_post)
    ROLE_FIXTURES.each do |role|
      assert_policy_permits GumroadBlog::PostsPolicy, record, role, :show?
    end
  end

  test "show? denies access to a different seller for unpublished post" do
    record = installments(:unpublished_post)
    ctx = SellerContext.new(user: users(:another_seller), seller: users(:another_seller))
    refute GumroadBlog::PostsPolicy.new(ctx, record).show?
  end

  test "show? denies access to anonymous users for unpublished post" do
    refute GumroadBlog::PostsPolicy.new(SellerContext.logged_out, installments(:unpublished_post)).show?
  end

  # --- show? : dead post --------------------------------------------------

  test "show? denies access to all roles for dead post" do
    record = installments(:dead_post)
    ROLE_FIXTURES.each do |role|
      refute_policy_permits GumroadBlog::PostsPolicy, record, role, :show?
    end
  end

  test "show? denies access to anonymous users for dead post" do
    refute GumroadBlog::PostsPolicy.new(SellerContext.logged_out, installments(:dead_post)).show?
  end

  # --- show? : hidden post (not shown on profile) -------------------------

  test "show? denies access to all roles for hidden post" do
    record = installments(:hidden_post)
    ROLE_FIXTURES.each do |role|
      refute_policy_permits GumroadBlog::PostsPolicy, record, role, :show?
    end
  end

  test "show? denies access to anonymous users for hidden post" do
    refute GumroadBlog::PostsPolicy.new(SellerContext.logged_out, installments(:hidden_post)).show?
  end

  # --- show? : workflow post ----------------------------------------------

  test "show? denies access to all roles for workflow post" do
    record = installments(:workflow_post)
    ROLE_FIXTURES.each do |role|
      refute_policy_permits GumroadBlog::PostsPolicy, record, role, :show?
    end
  end

  test "show? denies access to anonymous users for workflow post" do
    refute GumroadBlog::PostsPolicy.new(SellerContext.logged_out, installments(:workflow_post)).show?
  end

  # --- show? : non-audience post ------------------------------------------

  test "show? denies access to all roles for non-audience post" do
    record = installments(:no_audience_post)
    ROLE_FIXTURES.each do |role|
      refute_policy_permits GumroadBlog::PostsPolicy, record, role, :show?
    end
  end

  test "show? denies access to anonymous users for non-audience post" do
    refute GumroadBlog::PostsPolicy.new(SellerContext.logged_out, installments(:no_audience_post)).show?
  end
end
