# frozen_string_literal: true

require "test_helper"

class Charge::ChargeableTest < ActiveSupport::TestCase
  setup do
    @product = links(:basic_user_product)
    @seller = @product.user
  end

  # --- helpers ---

  def build_purchase(**attrs)
    p = Purchase.new(link: @product, seller: @seller, email: "ch-#{SecureRandom.hex(3)}@example.com",
                     purchase_state: "successful", total_transaction_cents: 1000,
                     displayed_price_cents: 1000, displayed_price_currency_type: "usd",
                     price_cents: 1000, fee_cents: 0)
    attrs.each { |k, v| p.send("#{k}=", v) }
    cols = p.attributes.compact.merge("created_at" => Time.current, "updated_at" => Time.current)
    cols.delete("id")
    id = Purchase.insert(cols).rows.first&.first ||
         Purchase.connection.select_value("SELECT LAST_INSERT_ID()")
    Purchase.find(id)
  end

  def build_charge(**attrs)
    order = Order.create!
    c = Charge.new(order: order, seller: @seller, **attrs)
    c.save!(validate: false)
    c
  end

  def dispute_event(**attrs)
    ev = ChargeEvent.new
    ev.type = ChargeEvent::TYPE_DISPUTE_FORMALIZED
    attrs.each { |k, v| ev.send("#{k}=", v) }
    ev
  end

  # ----- .find_by_stripe_event (Purchase) -----

  test ".find_by_stripe_event finds the purchase using charge reference that is purchase's external id" do
    purchase = build_purchase
    event = dispute_event(charge_reference: purchase.external_id)
    assert_equal purchase, Charge::Chargeable.find_by_stripe_event(event)
  end

  test ".find_by_stripe_event finds the purchase using charge id that is purchase's stripe transaction id" do
    purchase = build_purchase(stripe_transaction_id: "ch_12345")
    event = dispute_event(charge_reference: nil, charge_id: "ch_12345")
    assert_equal purchase, Charge::Chargeable.find_by_stripe_event(event)
  end

  test ".find_by_stripe_event finds the purchase using processor payment intent id" do
    purchase = build_purchase
    purchase.create_processor_payment_intent!(intent_id: "pi_123456")
    event = dispute_event(charge_reference: nil, charge_id: nil, processor_payment_intent_id: "pi_123456")
    assert_equal purchase, Charge::Chargeable.find_by_stripe_event(event)
  end

  # ----- .find_by_stripe_event (Charge) -----

  test ".find_by_stripe_event finds the charge using charge reference that is charge's id" do
    charge = build_charge
    event = dispute_event(charge_reference: "#{Charge::COMBINED_CHARGE_PREFIX}#{charge.id}")
    assert_equal charge, Charge::Chargeable.find_by_stripe_event(event)
  end

  test ".find_by_stripe_event finds the charge using charge id that is charge's processor transaction id" do
    charge = build_charge(processor_transaction_id: "ch_12345")
    event = dispute_event(charge_reference: "#{Charge::COMBINED_CHARGE_PREFIX}99999", charge_id: "ch_12345")
    assert_equal charge, Charge::Chargeable.find_by_stripe_event(event)
  end

  test ".find_by_stripe_event finds the charge using processor payment intent id" do
    charge = build_charge(stripe_payment_intent_id: "pi_123456")
    event = dispute_event(charge_reference: "#{Charge::COMBINED_CHARGE_PREFIX}99999",
                          charge_id: nil, processor_payment_intent_id: "pi_123456")
    assert_equal charge, Charge::Chargeable.find_by_stripe_event(event)
  end

  # ----- .find_by_processor_transaction_id! -----

  test ".find_by_processor_transaction_id! raises when no match" do
    assert_raises(ActiveRecord::RecordNotFound) do
      Charge::Chargeable.find_by_processor_transaction_id!("ch_no_match_#{SecureRandom.hex(4)}")
    end
  end

  test ".find_by_processor_transaction_id! returns the purchase when only the purchase matches" do
    txn_id = "ch_#{SecureRandom.hex(4)}"
    purchase = build_purchase(stripe_transaction_id: txn_id)
    assert_equal purchase, Charge::Chargeable.find_by_processor_transaction_id!(txn_id)
  end

  test ".find_by_processor_transaction_id! returns the charge when the charge also matches" do
    txn_id = "ch_#{SecureRandom.hex(4)}"
    purchase = build_purchase(stripe_transaction_id: txn_id)
    charge = build_charge(processor_transaction_id: txn_id)
    charge.purchases << purchase
    assert_equal charge, Charge::Chargeable.find_by_processor_transaction_id!(txn_id)
  end

  # ----- .find_by_purchase_or_charge! -----

  test ".find_by_purchase_or_charge! raises when both arguments are nil" do
    err = assert_raises(ArgumentError) do
      Charge::Chargeable.find_by_purchase_or_charge!(purchase: nil, charge: nil)
    end
    assert_equal "Either purchase or charge must be present", err.message
  end

  test ".find_by_purchase_or_charge! raises when both arguments are present" do
    purchase = build_purchase
    charge = build_charge
    charge.purchases << purchase
    err = assert_raises(ArgumentError) do
      Charge::Chargeable.find_by_purchase_or_charge!(purchase: purchase, charge: charge)
    end
    assert_equal "Only one of purchase or charge must be present", err.message
  end

  test ".find_by_purchase_or_charge! returns the purchase's charge when the purchase belongs to a charge" do
    purchase = build_purchase
    charge = build_charge
    charge.purchases << purchase
    assert_equal charge, Charge::Chargeable.find_by_purchase_or_charge!(purchase: purchase.reload)
  end

  test ".find_by_purchase_or_charge! returns the purchase when the purchase does not belong to a charge" do
    purchase = build_purchase
    assert_equal purchase, Charge::Chargeable.find_by_purchase_or_charge!(purchase: purchase)
  end

  # ----- #charged_purchases -----

  test "#charged_purchases for a Charge returns all non-free, non-free-trial purchases" do
    paid_1 = build_purchase(total_transaction_cents: 1000)
    paid_2 = build_purchase(total_transaction_cents: 1500)
    free = build_purchase(total_transaction_cents: 0, price_cents: 0, displayed_price_cents: 0)
    free_trial = build_purchase(flags: Purchase.flag_mapping["flags"][:is_free_trial_purchase])

    charge = build_charge
    charge.purchases << paid_1
    charge.purchases << paid_2
    charge.purchases << free
    charge.purchases << free_trial

    assert_equal [paid_1, paid_2].sort_by(&:id), charge.charged_purchases.sort_by(&:id)
  end

  test "#charged_purchases for a Purchase returns a single-item array containing the purchase itself" do
    purchase = build_purchase
    build_purchase
    assert_equal [purchase], purchase.charged_purchases
  end

  # ----- #successful_purchases -----

  test "#successful_purchases for a Charge returns purchases included in the charge with successful state" do
    p1 = build_purchase(purchase_state: "successful")
    p2 = build_purchase(purchase_state: "successful")
    p3 = build_purchase(purchase_state: "failed")
    charge = build_charge
    charge.purchases << p1 << p2 << p3
    assert_equal [p1, p2].sort_by(&:id), charge.successful_purchases.to_a.sort_by(&:id)
  end

  test "#successful_purchases for a Purchase returns the purchase itself" do
    purchase = build_purchase
    build_purchase
    assert_equal [purchase], purchase.successful_purchases.to_a
  end

  # NOTE: #update_processor_fee_cents! for Purchase calls AR `update!` which
  # re-runs the full Purchase validation chain (including the credit-card
  # check) — fixture purchases here lack the columns to satisfy it. The Charge
  # variant iterates and calls the same on each Purchase. Original spec was
  # tagged `:vcr` for that reason. Leave these to a follow-up tick.
end
