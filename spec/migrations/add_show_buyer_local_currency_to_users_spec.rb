# frozen_string_literal: true

require "spec_helper"
require Rails.root.join("db/migrate/20261129000000_add_show_buyer_local_currency_to_users")

describe AddShowBuyerLocalCurrencyToUsers do
  it "adds and removes the creator opt-in column" do
    connection = ActiveRecord::Base.connection
    migration = described_class.new

    migration.migrate(:down) if connection.column_exists?(:users, :show_buyer_local_currency)
    expect(connection.column_exists?(:users, :show_buyer_local_currency)).to eq(false)

    migration.migrate(:up)
    column = connection.columns(:users).find { _1.name == "show_buyer_local_currency" }

    expect(column).to be_present
    expect([false, "0"]).to include(column.default)
    expect(column.null).to eq(false)

    migration.migrate(:down)
    expect(connection.column_exists?(:users, :show_buyer_local_currency)).to eq(false)
  ensure
    migration ||= described_class.new
    migration.migrate(:up) unless ActiveRecord::Base.connection.column_exists?(:users, :show_buyer_local_currency)
    User.reset_column_information
  end
end
