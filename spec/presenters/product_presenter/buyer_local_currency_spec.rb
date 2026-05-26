# frozen_string_literal: true

require "spec_helper"

describe "ProductPresenter buyer local currency props" do
  fixtures :users, :links, :prices

  let(:request) do
    OpenStruct.new(
      remote_ip: "2.2.2.2",
      host: "example.com",
      host_with_port: "example.com",
      cookie_jar: {}
    )
  end

  before do
    allow(GeoIp).to receive(:lookup).with("2.2.2.2").and_return(
      GeoIp::Result.new(
        country_name: "France",
        country_code: "FR",
        region_name: nil,
        city_name: nil,
        postal_code: nil,
        latitude: nil,
        longitude: nil
      )
    )
  end

  def set_default_offer_code(product)
    offer_code = product.user.offer_codes.create!(
      code: "HALF#{product.id}",
      amount_percentage: 50,
      products: [product]
    )
    product.update!(default_offer_code: offer_code)
  end

  describe ProductPresenter::ProductProps do
    it "includes buyer local price when the creator opts in and the buyer currency is non-primary" do
      product = links(:buyer_currency_product)
      allow_any_instance_of(described_class).to receive(:buyer_local_currency_rate).and_return(BigDecimal("0.8"))

      props = described_class.new(product:).props(seller_custom_domain_url: nil, request:, pundit_user: nil)[:product]

      expect(props[:buyer_currency]).to eq("eur")
      expect(props[:buyer_local_price_cents]).to eq(800)
    end

    it "includes buyer local price and original price for an opted-in discounted product" do
      product = links(:buyer_currency_product)
      set_default_offer_code(product)
      allow_any_instance_of(described_class).to receive(:buyer_local_currency_rate).and_return(BigDecimal("0.8"))

      props = described_class.new(product:).props(seller_custom_domain_url: nil, request:, pundit_user: nil)[:product]

      expect(props[:buyer_currency]).to eq("eur")
      expect(props[:buyer_local_price_cents]).to eq(400)
      expect(props[:buyer_local_original_price_cents]).to eq(800)
    end

    it "omits buyer local price when the creator has not opted in" do
      product = links(:buyer_currency_product_disabled)
      set_default_offer_code(product)
      allow_any_instance_of(described_class).to receive(:buyer_local_currency_rate).and_return(BigDecimal("0.8"))

      props = described_class.new(product:).props(seller_custom_domain_url: nil, request:, pundit_user: nil)[:product]

      expect(props).not_to have_key(:buyer_currency)
      expect(props).not_to have_key(:buyer_local_price_cents)
      expect(props).not_to have_key(:buyer_local_original_price_cents)
    end

    it "omits buyer local price when the buyer currency matches the product currency" do
      product = links(:buyer_currency_product)
      allow(GeoIp).to receive(:lookup).with("2.2.2.2").and_return(
        GeoIp::Result.new(
          country_name: "United States",
          country_code: "US",
          region_name: nil,
          city_name: nil,
          postal_code: nil,
          latitude: nil,
          longitude: nil
        )
      )

      props = described_class.new(product:).props(seller_custom_domain_url: nil, request:, pundit_user: nil)[:product]

      expect(props).not_to have_key(:buyer_currency)
      expect(props).not_to have_key(:buyer_local_price_cents)
      expect(props).not_to have_key(:buyer_local_original_price_cents)
    end
  end

  describe ProductPresenter::Card do
    it "includes buyer local price for product cards when the creator opts in" do
      product = links(:buyer_currency_product)
      allow_any_instance_of(described_class).to receive(:buyer_local_currency_rate).and_return(BigDecimal("0.8"))

      props = described_class.new(product:).for_web(request:)

      expect(props[:buyer_currency]).to eq("eur")
      expect(props[:buyer_local_price_cents]).to eq(800)
    end

    it "includes buyer local price and original price for product cards with a pre-discount price" do
      product = links(:buyer_currency_product)
      set_default_offer_code(product)
      allow_any_instance_of(described_class).to receive(:buyer_local_currency_rate).and_return(BigDecimal("0.8"))

      props = described_class.new(product:).for_web(request:)

      expect(props[:buyer_currency]).to eq("eur")
      expect(props[:buyer_local_price_cents]).to eq(400)
      expect(props[:buyer_local_original_price_cents]).to eq(800)
    end
  end
end
