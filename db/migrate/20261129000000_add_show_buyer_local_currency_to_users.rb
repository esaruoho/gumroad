# frozen_string_literal: true

class AddShowBuyerLocalCurrencyToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :show_buyer_local_currency, :boolean, default: false, null: false
  end
end
