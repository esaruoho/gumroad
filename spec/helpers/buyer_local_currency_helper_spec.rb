# frozen_string_literal: true

require "spec_helper"

describe CurrencyHelper do
  let(:helper) { Class.new { include CurrencyHelper }.new }

  describe "#buyer_currency_for_country" do
    it "maps supported countries to buyer currencies" do
      expect(helper.buyer_currency_for_country("DE")).to eq("eur")
      expect(helper.buyer_currency_for_country("GB")).to eq("gbp")
      expect(helper.buyer_currency_for_country("JP")).to eq("jpy")
      expect(helper.buyer_currency_for_country("BR")).to eq("brl")
    end

    it "falls back to USD for unknown countries" do
      expect(helper.buyer_currency_for_country("ZZ")).to eq("usd")
      expect(helper.buyer_currency_for_country(nil)).to eq("usd")
    end
  end

  describe "#buyer_local_currency_rate" do
    around do |example|
      travel_to Date.new(2026, 5, 26) do
        $redis.del("buyer_local_currency_rate:usd:eur:2026-05-26")
        $redis.del("buyer_local_currency_rate:usd:eur:latest")
        example.run
        $redis.del("buyer_local_currency_rate:usd:eur:2026-05-26")
        $redis.del("buyer_local_currency_rate:usd:eur:latest")
      end
    end

    it "returns the cached daily rate" do
      $redis.set("buyer_local_currency_rate:usd:eur:2026-05-26", "0.8")

      expect(helper).not_to receive(:query_buyer_local_currency_rate)
      expect(helper.buyer_local_currency_rate(from_currency: "usd", to_currency: "eur")).to eq(BigDecimal("0.8"))
    end

    it "caches a daily snapshot rate" do
      expect(helper.buyer_local_currency_rate(from_currency: "usd", to_currency: "eur")).to eq(BigDecimal("0.81127"))
      expect($redis.get("buyer_local_currency_rate:usd:eur:2026-05-26")).to eq("0.81127")
      expect($redis.ttl("buyer_local_currency_rate:usd:eur:2026-05-26")).to be_between(1, 24.hours.to_i)
    end

    it "returns stale cache when the daily snapshot fails" do
      $redis.set("buyer_local_currency_rate:usd:eur:latest", "0.7")
      allow(helper).to receive(:query_buyer_local_currency_rate).and_raise(StandardError)

      expect(helper.buyer_local_currency_rate(from_currency: "usd", to_currency: "eur")).to eq(BigDecimal("0.7"))
    end

    it "skips the annotation when the daily snapshot fails without stale cache" do
      allow(helper).to receive(:query_buyer_local_currency_rate).and_raise(StandardError)

      expect(helper.buyer_local_currency_rate(from_currency: "usd", to_currency: "eur")).to be_nil
    end
  end

  describe "#buyer_local_price_cents" do
    it "rounds to the buyer currency minor units" do
      allow(helper).to receive(:buyer_local_currency_rate).with(from_currency: "usd", to_currency: "jpy").and_return(BigDecimal("150"))

      expect(helper.buyer_local_price_cents(price_cents: 199, from_currency: "usd", to_currency: "jpy")).to eq(299)
    end
  end
end
