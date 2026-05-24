# frozen_string_literal: true

require "test_helper"

class Admin::Products::StaffPicked::LinkPolicyTest < ActiveSupport::TestCase
  def setup
    @admin = users(:admin_user)
    @context = SellerContext.new(user: @admin, seller: @admin)
    @product = links(:named_seller_product)
  end

  def policy_for(record)
    Admin::Products::StaffPicked::LinkPolicy.new(@context, record)
  end

  # create?

  test "create? grants access when no staff_picked_product exists and product is recommendable" do
    @product.stub(:recommendable?, true) do
      assert policy_for(@product).create?
    end
  end

  test "create? grants access when staff_picked_product exists but is deleted, and product is recommendable" do
    @product.create_staff_picked_product!(deleted_at: Time.current)
    @product.stub(:recommendable?, true) do
      assert policy_for(@product).create?
    end
  end

  test "create? denies access when an alive staff_picked_product exists" do
    @product.create_staff_picked_product!
    @product.stub(:recommendable?, true) do
      refute policy_for(@product).create?
    end
  end

  test "create? denies access when product is not recommendable" do
    @product.stub(:recommendable?, false) do
      refute policy_for(@product).create?
    end
  end

  # destroy?

  test "destroy? grants access when an alive staff_picked_product exists" do
    @product.create_staff_picked_product!
    assert policy_for(@product).destroy?
  end

  test "destroy? denies access when staff_picked_product is deleted" do
    @product.create_staff_picked_product!(deleted_at: Time.current)
    refute policy_for(@product).destroy?
  end
end
