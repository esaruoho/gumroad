# frozen_string_literal: true

require "test_helper"

class Products::Variants::LinkPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  ACTIONS = %i[index?].freeze

  test "grants access to owner" do
    assert_policy_permits Products::Variants::LinkPolicy,
                          links(:named_seller_product), :named_seller, *ACTIONS
  end

  test "grants access to accountant" do
    assert_policy_permits Products::Variants::LinkPolicy,
                          links(:named_seller_product), :accountant_for_named_seller, *ACTIONS
  end

  test "grants access to admin" do
    assert_policy_permits Products::Variants::LinkPolicy,
                          links(:named_seller_product), :admin_for_named_seller, *ACTIONS
  end

  test "grants access to marketing" do
    assert_policy_permits Products::Variants::LinkPolicy,
                          links(:named_seller_product), :marketing_for_named_seller, *ACTIONS
  end

  test "grants access to support" do
    assert_policy_permits Products::Variants::LinkPolicy,
                          links(:named_seller_product), :support_for_named_seller, *ACTIONS
  end
end
