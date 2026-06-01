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

    it "returns nil for unknown countries" do
      expect(helper.buyer_currency_for_country("ZZ")).to be_nil
      expect(helper.buyer_currency_for_country(nil)).to be_nil
    end
  end

  describe "#buyer_currency_for_ip" do
    it "returns nil when GeoIP lookup fails" do
      allow(GeoIp).to receive(:lookup).with("2.2.2.2").and_raise(StandardError)

      expect(helper.buyer_currency_for_ip("2.2.2.2")).to be_nil
    end
  end

  describe "#buyer_local_currency_rate" do
    let(:currency_namespace) { helper.currency_namespace }

    around do |example|
      travel_to Date.new(2026, 5, 26) do
        currency_namespace.del("buyer_local_currency_rate:usd:eur:2026-05-26")
        currency_namespace.del("buyer_local_currency_rate:usd:eur:latest")
        currency_namespace.del("buyer_local_currency_rate:usd:eur:prewarm_enqueued")
        example.run
        currency_namespace.del("buyer_local_currency_rate:usd:eur:2026-05-26")
        currency_namespace.del("buyer_local_currency_rate:usd:eur:latest")
        currency_namespace.del("buyer_local_currency_rate:usd:eur:prewarm_enqueued")
      end
    end

    it "returns the cached daily rate without enqueuing a refresh" do
      currency_namespace.set("buyer_local_currency_rate:usd:eur:2026-05-26", "0.8")

      expect(PrewarmBuyerLocalCurrencyRateJob).not_to receive(:perform_async)
      expect(helper.buyer_local_currency_rate(from_currency: "usd", to_currency: "eur")).to eq(BigDecimal("0.8"))
    end

    it "returns stale cache and enqueues a refresh on cold cache" do
      currency_namespace.set("buyer_local_currency_rate:usd:eur:latest", "0.7")

      expect(PrewarmBuyerLocalCurrencyRateJob).to receive(:perform_async).with("usd", "eur")
      expect(helper.buyer_local_currency_rate(from_currency: "usd", to_currency: "eur")).to eq(BigDecimal("0.7"))
    end

    it "returns nil and enqueues a refresh when no stale cache exists" do
      expect(PrewarmBuyerLocalCurrencyRateJob).to receive(:perform_async).with("usd", "eur")
      expect(helper.buyer_local_currency_rate(from_currency: "usd", to_currency: "eur")).to be_nil
    end

    it "debounces the refresh enqueue across repeated cold-cache reads" do
      expect(PrewarmBuyerLocalCurrencyRateJob).to receive(:perform_async).with("usd", "eur").once

      3.times { helper.buyer_local_currency_rate(from_currency: "usd", to_currency: "eur") }
    end
  end

  describe "#refresh_buyer_local_currency_rate!" do
    let(:currency_namespace) { helper.currency_namespace }

    around do |example|
      travel_to Date.new(2026, 5, 26) do
        currency_namespace.del("buyer_local_currency_rate:usd:eur:2026-05-26")
        currency_namespace.del("buyer_local_currency_rate:usd:eur:latest")
        example.run
        currency_namespace.del("buyer_local_currency_rate:usd:eur:2026-05-26")
        currency_namespace.del("buyer_local_currency_rate:usd:eur:latest")
      end
    end

    it "queries the live rate and writes both daily and stale caches" do
      allow(helper).to receive(:query_buyer_local_currency_rate).and_return(BigDecimal("0.81127"))
      expect(helper.refresh_buyer_local_currency_rate!(from_currency: "usd", to_currency: "eur")).to eq(BigDecimal("0.81127"))
      expect(currency_namespace.get("buyer_local_currency_rate:usd:eur:2026-05-26")).to eq("0.81127")
      expect(currency_namespace.get("buyer_local_currency_rate:usd:eur:latest")).to eq("0.81127")
      expect(currency_namespace.ttl("buyer_local_currency_rate:usd:eur:2026-05-26")).to be_between(1, 24.hours.to_i)
    end

    it "returns nil when the live query fails" do
      allow(helper).to receive(:query_buyer_local_currency_rate).and_raise(StandardError)

      expect(helper.refresh_buyer_local_currency_rate!(from_currency: "usd", to_currency: "eur")).to be_nil
    end
  end

  describe "#buyer_local_price_cents" do
    it "rounds to the buyer currency minor units" do
      allow(helper).to receive(:buyer_local_currency_rate).with(from_currency: "usd", to_currency: "jpy").and_return(BigDecimal("150"))

      expect(helper.buyer_local_price_cents(price_cents: 199, from_currency: "usd", to_currency: "jpy")).to eq(299)
    end
  end

  describe "#buyer_currency_display_props" do
    let(:product) do
      user = build_stubbed(:user)
      build_stubbed(:product, user:, price_currency_type: "usd").tap do |p|
        allow(p.user).to receive(:show_buyer_local_currency?).and_return(true)
        allow(p).to receive(:external_id).and_return("prod_abc")
      end
    end

    it "returns a safe static default without re-raising when an operation raises" do
      # The rescue must NOT re-run the operations that may have thrown
      # (show_buyer_local_currency?, price_currency_type) — regression for the
      # rescue-handler-re-executes-failed-operations finding.
      allow(helper).to receive(:buyer_currency_for_ip).and_raise(StandardError)

      props = nil
      expect do
        props = helper.buyer_currency_display_props(product:, price_cents: 1000, ip: "1.2.3.4")
      end.not_to raise_error

      expect(props).to include(
        product_id: "prod_abc",
        variant: "default",
        buyer_local_price_cents: nil,
        rate: nil
      )
    end
  end
end
