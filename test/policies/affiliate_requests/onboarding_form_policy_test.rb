# frozen_string_literal: true

require "test_helper"

class AffiliateRequests::OnboardingFormPolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  ACTIONS = %i[update?].freeze

  test "grants access to owner" do
    assert_policy_permits AffiliateRequests::OnboardingFormPolicy, :onboarding_form, :named_seller, *ACTIONS
  end

  test "denies access to accountant" do
    refute_policy_permits AffiliateRequests::OnboardingFormPolicy, :onboarding_form, :accountant_for_named_seller, *ACTIONS
  end

  test "grants access to admin" do
    assert_policy_permits AffiliateRequests::OnboardingFormPolicy, :onboarding_form, :admin_for_named_seller, *ACTIONS
  end

  test "denies access to support" do
    refute_policy_permits AffiliateRequests::OnboardingFormPolicy, :onboarding_form, :support_for_named_seller, *ACTIONS
  end
end
