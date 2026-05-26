# frozen_string_literal: true

require "spec_helper"

describe User do
  fixtures :users

  describe "#show_buyer_local_currency" do
    it "reads and writes the creator opt-in attribute" do
      seller = users(:buyer_currency_seller)

      expect(seller.show_buyer_local_currency).to eq(true)

      seller.update!(show_buyer_local_currency: false)

      expect(seller.reload.show_buyer_local_currency).to eq(false)
    end
  end
end
