# frozen_string_literal: true

require "test_helper"

class Settings::BillingPolicyTest < ActiveSupport::TestCase
  ACTIONS = %i[show? update?].freeze

  test "grants access when the viewer is the seller themselves" do
    owner = users(:named_seller)
    context = SellerContext.new(user: owner, seller: owner)
    ACTIONS.each do |action|
      assert Settings::BillingPolicy.new(context, nil).public_send(action),
             "expected Settings::BillingPolicy##{action} to permit owner viewing themselves"
    end
  end

  test "denies access when the viewer is a different user on the seller account" do
    owner = users(:named_seller)
    other = users(:basic_user)
    context = SellerContext.new(user: other, seller: owner)
    ACTIONS.each do |action|
      refute Settings::BillingPolicy.new(context, nil).public_send(action),
             "expected Settings::BillingPolicy##{action} to deny non-seller user"
    end
  end
end
