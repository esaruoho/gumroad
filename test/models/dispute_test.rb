require "test_helper"

class DisputeTest < ActiveSupport::TestCase
  test "creation sets seller when creating from a purchase" do
    purchase = purchases(:auto_invoice_enabled_purchase)
    dispute = Dispute.create!(purchase: purchase, state: "created", event_created_at: Time.current)
    assert_equal purchase.seller, dispute.seller
  end

  test "creation sets seller when creating from a charge" do
    charge = charges(:admin_charge_policy_charge)
    dispute = Dispute.create!(charge: charge, state: "created", event_created_at: Time.current)
    assert_equal charge.seller, dispute.seller
  end

  test "creation can't be created without a purchase or a charge" do
    dispute = Dispute.new(state: "created", event_created_at: Time.current)
    refute dispute.valid?
    assert_equal "A Disputable object must be provided.", dispute.errors[:base][0]
  end

  test "creation can't be created with both purchase and charge" do
    dispute = Dispute.new(
      purchase: purchases(:auto_invoice_enabled_purchase),
      charge: charges(:admin_charge_policy_charge),
      state: "created",
      event_created_at: Time.current,
    )
    refute dispute.valid?
    assert_equal "Only one Disputable object must be provided.", dispute.errors[:base][0]
  end

  test "#disputable returns the associated purchase if dispute belongs to a purchase" do
    purchase = purchases(:auto_invoice_enabled_purchase)
    dispute = Dispute.create!(purchase: purchase, state: "created", event_created_at: Time.current)
    assert_equal purchase, dispute.disputable
  end

  test "#disputable returns the associated charge if dispute belongs to a charge" do
    charge = charges(:admin_charge_policy_charge)
    dispute = Dispute.create!(charge: charge, state: "created", event_created_at: Time.current)
    assert_equal charge, dispute.disputable
  end
end
