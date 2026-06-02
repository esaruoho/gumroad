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

    before do
      currency_namespace.set("EUR", "0.8")
      currency_namespace.set("JPY", "150")
    end

    after do
      currency_namespace.del("EUR")
      currency_namespace.del("JPY")
    end

    it "derives the cross rate from the hourly-cached USD rates without calling OXR" do
      expect(URI).not_to receive(:open)

      expect(helper.buyer_local_currency_rate(from_currency: "usd", to_currency: "eur")).to eq(BigDecimal("0.8"))
      expect(helper.buyer_local_currency_rate(from_currency: "eur", to_currency: "jpy")).to eq(BigDecimal("187.5"))
    end

    it "returns 1 when both currencies are the same" do
      expect(helper.buyer_local_currency_rate(from_currency: "eur", to_currency: "eur")).to eq(BigDecimal("1"))
    end

    it "returns nil when a rate is missing from the cache" do
      currency_namespace.del("EUR")

      expect(helper.buyer_local_currency_rate(from_currency: "usd", to_currency: "eur")).to be_nil
    end
  end

  describe "#cached_usd_rate" do
    let(:currency_namespace) { helper.currency_namespace }

    after { currency_namespace.del("EUR") }

    it "returns 1 for USD" do
      expect(helper.cached_usd_rate("usd")).to eq(BigDecimal("1"))
    end

    it "returns the cached rate for a known currency" do
      currency_namespace.set("EUR", "0.8")

      expect(helper.cached_usd_rate("eur")).to eq(BigDecimal("0.8"))
    end

    it "returns nil when the rate is missing" do
      currency_namespace.del("EUR")

      expect(helper.cached_usd_rate("eur")).to be_nil
    end

    it "returns nil when the cached rate is non-positive" do
      currency_namespace.set("EUR", "0")

      expect(helper.cached_usd_rate("eur")).to be_nil
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
