# frozen_string_literal: true

require "spec_helper"

describe Purchase::Refundable do
  describe "#processor_refund_amount_cents" do
    it "returns the proportional charge-currency amount using the locked buyer amount" do
      purchase = build(:purchase, price_cents: 10_00, total_transaction_cents: 10_00)
      purchase.buyer_currency = "eur"
      purchase.buyer_currency_amount_cents = 9_20
      purchase.buyer_currency_exchange_rate = 0.92

      expect(purchase.processor_refund_amount_cents(5_00)).to eq(4_60)
    end

    it "keeps USD refunds in USD cents" do
      purchase = build(:purchase, price_cents: 10_00, total_transaction_cents: 10_00)

      expect(purchase.processor_refund_amount_cents(5_00)).to eq(5_00)
    end
  end
end
