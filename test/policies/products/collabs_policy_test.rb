# frozen_string_literal: true

require "test_helper"

class Products::CollabsPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  ACTIONS = %i[index?].freeze

  test "grants access to owner" do
    assert_policy_permits Products::CollabsPolicy, :collabs, :named_seller, *ACTIONS
  end

  test "grants access to accountant" do
    assert_policy_permits Products::CollabsPolicy, :collabs, :accountant_for_named_seller, *ACTIONS
  end

  test "grants access to admin" do
    assert_policy_permits Products::CollabsPolicy, :collabs, :admin_for_named_seller, *ACTIONS
  end

  test "grants access to marketing" do
    assert_policy_permits Products::CollabsPolicy, :collabs, :marketing_for_named_seller, *ACTIONS
  end

  test "grants access to support" do
    assert_policy_permits Products::CollabsPolicy, :collabs, :support_for_named_seller, *ACTIONS
  end
end
