# frozen_string_literal: true

require "spec_helper"

describe BuyerCurrencyService do
  describe ".detect_currency" do
    it "returns nil for blank IP" do
      expect(described_class.detect_currency(nil)).to be_nil
      expect(described_class.detect_currency("")).to be_nil
    end

    it "returns usd for US IPs" do
      allow(GeoIp).to receive(:lookup).and_return(
        GeoIp::Result.new(country_name: "United States", country_code: "US",
                          region_name: "CA", city_name: "SF", postal_code: "94105",
                          latitude: 37.7, longitude: -122.4)
      )
      expect(described_class.detect_currency("1.2.3.4")).to eq("usd")
    end

    it "returns eur for German IPs" do
      allow(GeoIp).to receive(:lookup).and_return(
        GeoIp::Result.new(country_name: "Germany", country_code: "DE",
                          region_name: nil, city_name: nil, postal_code: nil,
                          latitude: nil, longitude: nil)
      )
      expect(described_class.detect_currency("5.6.7.8")).to eq("eur")
    end

    it "returns jpy for Japanese IPs" do
      allow(GeoIp).to receive(:lookup).and_return(
        GeoIp::Result.new(country_name: "Japan", country_code: "JP",
                          region_name: nil, city_name: nil, postal_code: nil,
                          latitude: nil, longitude: nil)
      )
      expect(described_class.detect_currency("9.10.11.12")).to eq("jpy")
    end

    it "returns nil for countries not in the mapping" do
      allow(GeoIp).to receive(:lookup).and_return(
        GeoIp::Result.new(country_name: "Thailand", country_code: "TH",
                          region_name: nil, city_name: nil, postal_code: nil,
                          latitude: nil, longitude: nil)
      )
      expect(described_class.detect_currency("13.14.15.16")).to be_nil
    end
  end

  describe ".smart_round" do
    context "with decimal currencies (USD/EUR/GBP)" do
      it "rounds to .99 for prices under $10" do
        # $4.23 → $4.99
        expect(described_class.smart_round(423, "usd")).to eq(499)
      end

      it "rounds to .99 for prices in the $10-$50 range" do
        # $14.23 → $14.99
        expect(described_class.smart_round(1423, "usd")).to eq(1499)
        # $49.50 → $49.99
        expect(described_class.smart_round(4950, "usd")).to eq(4999)
      end

      it "rounds to .99 for prices in the $50-$100 range" do
        # $72.34 → $72.99
        expect(described_class.smart_round(7234, "usd")).to eq(7299)
      end

      it "rounds to X4.99 or X9.99 for $100-$500 range" do
        # $123.45 → round to nearest $5 → $125.00 → -1 → $124.99
        expect(described_class.smart_round(12345, "usd")).to eq(12499)
        # $200.00 → round to nearest $5 → $200.00 → -1 → $199.99
        expect(described_class.smart_round(20000, "usd")).to eq(19999)
      end

      it "returns 0 for zero amounts" do
        expect(described_class.smart_round(0, "usd")).to eq(0)
      end

      it "works with EUR" do
        expect(described_class.smart_round(423, "eur")).to eq(499)
      end
    end

    context "with JPY (zero-decimal)" do
      it "rounds to nearest 10 for prices under ¥100" do
        expect(described_class.smart_round(73, "jpy")).to eq(70)
      end

      it "rounds to nearest 100 for prices ¥500-¥1000" do
        expect(described_class.smart_round(750, "jpy")).to eq(800)
      end

      it "rounds to nearest 500 for prices ¥1000-¥5000" do
        expect(described_class.smart_round(2300, "jpy")).to eq(2500)
      end

      it "rounds to nearest 1000 for prices above ¥5000" do
        expect(described_class.smart_round(7500, "jpy")).to eq(8000)
      end
    end

    context "with KRW" do
      it "rounds to nearest 1000 for prices ₩5000-₩10000" do
        expect(described_class.smart_round(7500, "krw")).to eq(8000)
      end

      it "rounds to nearest 10000 for prices above ₩100000" do
        expect(described_class.smart_round(145000, "krw")).to eq(150000)
      end
    end
  end

  describe ".convert_price" do
    before do
      # Mock exchange rates: USD base
      allow_any_instance_of(CurrencyHelper).to receive(:get_rate).with("usd").and_return(1.0)
      allow_any_instance_of(CurrencyHelper).to receive(:get_rate).with("eur").and_return(0.92)
      allow_any_instance_of(CurrencyHelper).to receive(:get_rate).with("jpy").and_return(155.0)
      allow_any_instance_of(CurrencyHelper).to receive(:get_rate).with("gbp").and_return(0.79)
    end

    it "returns the same amount for same currency" do
      expect(described_class.convert_price(999, from_currency: "usd", to_currency: "usd")).to eq(999)
    end

    it "returns 0 for zero amount" do
      expect(described_class.convert_price(0, from_currency: "usd", to_currency: "eur")).to eq(0)
    end

    it "converts and smart-rounds USD to EUR" do
      # $9.99 → ~€9.19 → smart rounds to €9.99
      result = described_class.convert_price(999, from_currency: "usd", to_currency: "eur")
      expect(result).to be > 0
      expect(result % 100).to eq(99) # should end in .99
    end

    it "converts and smart-rounds USD to JPY" do
      # $9.99 → ~¥1549 → smart rounds to ¥1500
      result = described_class.convert_price(999, from_currency: "usd", to_currency: "jpy")
      expect(result).to be > 0
      expect(result % 500).to eq(0) # should be a round JPY number
    end
  end
end
