# frozen_string_literal: true

require "test_helper"

class Settings::Team::UserPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  ACTIONS = %i[show?].freeze

  test "show? grants access to owner" do
    assert_policy_permits Settings::Team::UserPolicy, users(:named_seller), :named_seller, *ACTIONS
  end

  test "show? grants access to admin" do
    assert_policy_permits Settings::Team::UserPolicy, users(:named_seller), :admin_for_named_seller, *ACTIONS
  end

  test "show? grants access to marketing" do
    assert_policy_permits Settings::Team::UserPolicy, users(:named_seller), :marketing_for_named_seller, *ACTIONS
  end
end
