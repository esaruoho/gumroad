# frozen_string_literal: true

class AddBuyerCurrencyToPurchases < ActiveRecord::Migration[7.1]
  def change
    add_column :purchases, :buyer_currency, :string, limit: 3
    add_column :purchases, :buyer_currency_amount_cents, :integer
    add_column :purchases, :buyer_currency_exchange_rate, :decimal, precision: 20, scale: 10
    add_index :purchases, :buyer_currency
  end
end
