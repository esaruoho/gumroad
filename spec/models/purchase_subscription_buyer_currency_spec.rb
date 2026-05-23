# frozen_string_literal: true

require "spec_helper"

describe "subscription buyer currency locking" do
  it "copies the original purchase buyer-currency amount onto recurring charges" do
    original_purchase = build(:purchase)
    original_purchase.buyer_currency = "eur"
    original_purchase.buyer_currency_amount_cents = 9_20
    original_purchase.buyer_currency_exchange_rate = 0.92

    purchase = build(:purchase)
    allow(purchase).to receive(:is_recurring_subscription_charge).and_return(true)
    allow(purchase).to receive(:subscription).and_return(instance_double(Subscription, original_purchase:))

    purchase.send(:apply_original_subscription_buyer_currency_amount)

    expect(purchase.buyer_currency).to eq("eur")
    expect(purchase.buyer_currency_amount_cents).to eq(9_20)
    expect(purchase.buyer_currency_exchange_rate.to_s).to eq("0.92")
  end
end
