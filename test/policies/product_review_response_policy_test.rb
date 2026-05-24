# frozen_string_literal: true
require "test_helper"

class ProductReviewResponsePolicyTest < ActiveSupport::TestCase
  include PolicyAssertions

  ACTIONS = %i[update? destroy?].freeze

  # Response on named_seller's product
  test "grants owner update/destroy on own response" do
    assert_policy_permits ProductReviewResponsePolicy, product_review_responses(:named_seller_product_review_response), :named_seller, *ACTIONS
  end

  test "grants admin update/destroy on seller's response" do
    assert_policy_permits ProductReviewResponsePolicy, product_review_responses(:named_seller_product_review_response), :admin_for_named_seller, *ACTIONS
  end

  test "grants support update/destroy on seller's response" do
    assert_policy_permits ProductReviewResponsePolicy, product_review_responses(:named_seller_product_review_response), :support_for_named_seller, *ACTIONS
  end

  test "denies accountant update/destroy on seller's response" do
    refute_policy_permits ProductReviewResponsePolicy, product_review_responses(:named_seller_product_review_response), :accountant_for_named_seller, *ACTIONS
  end

  test "denies marketing update/destroy on seller's response" do
    refute_policy_permits ProductReviewResponsePolicy, product_review_responses(:named_seller_product_review_response), :marketing_for_named_seller, *ACTIONS
  end

  # Response on another seller's product — all 5 roles denied
  test "denies owner update/destroy on another seller's response" do
    refute_policy_permits ProductReviewResponsePolicy, product_review_responses(:another_seller_product_review_response), :named_seller, *ACTIONS
  end

  test "denies admin update/destroy on another seller's response" do
    refute_policy_permits ProductReviewResponsePolicy, product_review_responses(:another_seller_product_review_response), :admin_for_named_seller, *ACTIONS
  end

  test "denies support update/destroy on another seller's response" do
    refute_policy_permits ProductReviewResponsePolicy, product_review_responses(:another_seller_product_review_response), :support_for_named_seller, *ACTIONS
  end

  test "denies accountant update/destroy on another seller's response" do
    refute_policy_permits ProductReviewResponsePolicy, product_review_responses(:another_seller_product_review_response), :accountant_for_named_seller, *ACTIONS
  end

  test "denies marketing update/destroy on another seller's response" do
    refute_policy_permits ProductReviewResponsePolicy, product_review_responses(:another_seller_product_review_response), :marketing_for_named_seller, *ACTIONS
  end
end
