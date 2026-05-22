# frozen_string_literal: true

require "spec_helper"

describe "Multi-currency checkout", type: :system, js: true do
  let(:seller) { create(:named_seller) }
  let!(:product) { create(:product, user: seller, price_cents: 10000, name: "Test Product") }

  before do
    create(:merchant_account_stripe, user: seller)
  end

  describe "product page pricing" do
    context "when multi_currency_checkout flag is enabled" do
      before { Flipper.enable(:multi_currency_checkout) }
      after { Flipper.disable(:multi_currency_checkout) }

      it "shows local currency price for non-US buyer" do
        allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return("2.47.255.255") # Italy → EUR
        stub_currency_conversion("usd", "eur", rate: 0.92)

        visit short_link_path(product.unique_permalink)
        expect(page).to have_text("€")
        expect(page).not_to have_text("$100")
      end

      it "shows USD price for US buyers" do
        allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return("8.8.8.8") # US → USD
        visit short_link_path(product.unique_permalink)
        expect(page).to have_text("$100")
      end

      it "shows USD price for buyers in unmapped countries" do
        allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return("171.96.70.108") # Thailand → not mapped
        visit short_link_path(product.unique_permalink)
        expect(page).to have_text("$100")
      end
    end

    context "when multi_currency_checkout flag is disabled" do
      it "shows USD price regardless of buyer location" do
        allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return("2.47.255.255") # Italy
        visit short_link_path(product.unique_permalink)
        expect(page).to have_text("$100")
      end
    end
  end

  describe "checkout page" do
    let(:buyer) { create(:user) }

    context "when multi_currency_checkout flag is enabled" do
      before { Flipper.enable(:multi_currency_checkout) }
      after { Flipper.disable(:multi_currency_checkout) }

      it "shows local currency on checkout for non-US buyer" do
        allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return("81.2.69.142") # UK → GBP
        stub_currency_conversion("usd", "gbp", rate: 0.79)

        visit checkout_path(product.unique_permalink)
        expect(page).to have_text("£")
      end
    end

    context "when multi_currency_checkout flag is disabled" do
      it "shows USD on checkout regardless of buyer location" do
        allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return("81.2.69.142") # UK
        visit checkout_path(product.unique_permalink)
        expect(page).to have_text("$100")
      end
    end
  end

  private

  def stub_currency_conversion(from, to, rate:)
    allow_any_instance_of(BuyerCurrencyService).to receive(:get_usd_cents) { |_, _, cents| cents }
    allow_any_instance_of(BuyerCurrencyService).to receive(:usd_cents_to_currency) { |_, _, cents| (cents * rate).round }
    allow(BuyerCurrencyService).to receive(:exchange_rate).with(from_currency: from, to_currency: to).and_return(rate)
  end
end
