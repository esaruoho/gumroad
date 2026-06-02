# frozen_string_literal: true

require "spec_helper"

describe "Custom HTML product page", type: :system, js: true do
  let(:seller) { create(:user) }
  let(:product) do
    create(
      :product,
      user: seller,
      quantity_enabled: true,
      custom_html: <<~HTML
        <main>
          <h1>Custom landing</h1>
          <button type="button" data-gumroad-action="buy" data-gumroad-quantity="2">Buy from iframe</button>
        </main>
      HTML
    )
  end

  before do
    Feature.activate_user(:custom_html_pages, seller)
  end

  it "navigates from the sandboxed landing iframe to checkout when the buy control is clicked" do
    visit short_link_path(product)

    expect(page).to have_selector("iframe#gumroad-landing-frame")
    within_frame(find("iframe#gumroad-landing-frame")) do
      expect(page).to have_text("Custom landing")
      click_on "Buy from iframe"
    end

    expect(page).to have_current_path(/^\/checkout/, wait: 10)
    within_cart_item(product.name) do
      expect(page).to have_text("Qty: 2")
    end
  end

  context "with a pay-what-you-want price input" do
    let(:product) do
      create(
        :product,
        user: seller,
        customizable_price: true,
        price_cents: 100,
        custom_html: <<~HTML
          <main>
            <h1>Name your price</h1>
            <input data-gumroad-price-input type="number" min="0" step="0.01" aria-label="Your price" />
            <button type="button" data-gumroad-action="buy">Buy from iframe</button>
          </main>
        HTML
      )
    end

    it "carries the buyer-entered price through to checkout" do
      visit short_link_path(product)

      within_frame(find("iframe#gumroad-landing-frame")) do
        fill_in "Your price", with: "5"
        click_on "Buy from iframe"
      end

      expect(page).to have_current_path(/^\/checkout/, wait: 10)
      within_cart_item(product.name) do
        expect(page).to have_text("$5")
      end
    end

    it "falls back to the native price-entry page when the buyer leaves the price empty" do
      visit short_link_path(product)

      within_frame(find("iframe#gumroad-landing-frame")) do
        click_on "Buy from iframe"
      end

      expect(page).to have_field("Name a fair price", wait: 10)
    end

    it "ignores a negative price and falls back to the native price-entry page" do
      visit short_link_path(product)

      within_frame(find("iframe#gumroad-landing-frame")) do
        fill_in "Your price", with: "-5"
        click_on "Buy from iframe"
      end

      expect(page).to have_field("Name a fair price", wait: 10)
    end
  end

  context "with a preset price button alongside a price input" do
    let(:product) do
      create(
        :product,
        user: seller,
        customizable_price: true,
        price_cents: 100,
        custom_html: <<~HTML
          <main>
            <button type="button" data-gumroad-action="buy" data-gumroad-price="5">Pay $5</button>
            <input data-gumroad-price-input type="number" min="0" step="0.01" aria-label="Your price" />
            <button type="button" data-gumroad-action="buy">Pay custom amount</button>
          </main>
        HTML
      )
    end

    it "uses the preset button's price and ignores the shared empty price input" do
      visit short_link_path(product)

      within_frame(find("iframe#gumroad-landing-frame")) do
        click_on "Pay $5"
      end

      expect(page).to have_current_path(/^\/checkout/, wait: 10)
      within_cart_item(product.name) do
        expect(page).to have_text("$5")
      end
    end
  end
end
