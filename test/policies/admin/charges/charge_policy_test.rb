# frozen_string_literal: true

require "test_helper"

class Admin::Charges::ChargePolicyTest < ActiveSupport::TestCase
  def setup
    @admin = users(:admin_user)
    @seller_context = SellerContext.new(user: @admin, seller: @admin)
    @charge = charges(:admin_charge_policy_charge)
    @purchases = [
      purchases(:admin_charge_policy_purchase_1),
      purchases(:admin_charge_policy_purchase_2)
    ]
  end

  # ---- refund? -----------------------------------------------------------

  test "refund? grants access when charge has non-refunded successful purchases" do
    assert Admin::Charges::ChargePolicy.new(@seller_context, @charge).refund?
  end

  test "refund? denies access when all purchases are already refunded" do
    @purchases.each { |p| p.update_columns(stripe_refunded: 1) }
    refute Admin::Charges::ChargePolicy.new(@seller_context, @charge).refund?
  end

  # ---- sync_status_with_charge_processor? --------------------------------

  test "sync_status grants access when charge has in_progress purchases" do
    @purchases.each { |p| p.update_columns(purchase_state: "in_progress", succeeded_at: nil) }
    assert Admin::Charges::ChargePolicy.new(@seller_context, @charge).sync_status_with_charge_processor?
  end

  test "sync_status grants access when charge has failed purchases" do
    @purchases.each { |p| p.update_columns(purchase_state: "failed", succeeded_at: nil) }
    assert Admin::Charges::ChargePolicy.new(@seller_context, @charge).sync_status_with_charge_processor?
  end

  test "sync_status denies access when no purchases are in progress or failed" do
    # Fixture sets purchase_state: successful → already not in {in_progress, failed}.
    refute Admin::Charges::ChargePolicy.new(@seller_context, @charge).sync_status_with_charge_processor?
  end
end
