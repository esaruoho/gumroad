# frozen_string_literal: true

require "test_helper"

class StripeTransferExternallyToGumroadTest < ActiveSupport::TestCase
  def fake_balance(available_list)
    Stripe::Balance.construct_from(available: available_list)
  end

  setup do
    @balance = fake_balance([
      { "currency" => "usd", "amount" => 100 },
      { "currency" => "cad", "amount" => 200 }
    ])
  end

  test "available_balances returns a hash of currencies to integer cent balances" do
    Stripe::Balance.stub :retrieve, @balance do
      result = StripeTransferExternallyToGumroad.available_balances
      assert_kind_of Hash, result
      assert_includes result.keys, "usd"
      result.each_value { |v| assert_kind_of Integer, v }
    end
  end

  test "transfer creates a Stripe payout with amount and currency" do
    captured = nil
    Stripe::Payout.stub :create, ->(args) { captured = args; nil } do
      travel_to(Time.zone.local(2015, 4, 7)) do
        StripeTransferExternallyToGumroad.transfer("usd", 1234)
      end
    end
    assert_equal 1234, captured[:amount]
    assert_equal "usd", captured[:currency]
  end

  test "transfer sets a description that includes timestamp" do
    captured = nil
    Stripe::Payout.stub :create, ->(args) { captured = args; nil } do
      travel_to(Time.zone.local(2015, 4, 7)) do
        StripeTransferExternallyToGumroad.transfer("usd", 1234)
      end
    end
    assert_equal "USD 150407 0000", captured[:description]
  end

  test "transfer_all_available_balances creates a stripe transfer for each available balance" do
    calls = []
    StripeTransferExternallyToGumroad.stub :available_balances, { "usd" => 100_00 } do
      StripeTransferExternallyToGumroad.stub :transfer, ->(c, a) { calls << [c, a] } do
        StripeTransferExternallyToGumroad.transfer_all_available_balances
      end
    end
    assert_equal [["usd", 100_00]], calls
  end

  test "transfer_all_available_balances caps transfer at 99_999_999_99 cents" do
    calls = []
    StripeTransferExternallyToGumroad.stub :available_balances, { "usd" => 100_000_000_00 } do
      StripeTransferExternallyToGumroad.stub :transfer, ->(c, a) { calls << [c, a] } do
        StripeTransferExternallyToGumroad.transfer_all_available_balances
      end
    end
    assert_equal [["usd", 99_999_999_99]], calls
  end

  test "transfer_all_available_balances skips zero balances" do
    calls = []
    StripeTransferExternallyToGumroad.stub :available_balances, { "usd" => 0, "cad" => 100 } do
      StripeTransferExternallyToGumroad.stub :transfer, ->(c, a) { calls << [c, a] } do
        StripeTransferExternallyToGumroad.transfer_all_available_balances
      end
    end
    assert_equal [["cad", 100]], calls
  end

  test "transfer_all_available_balances skips negative balances" do
    calls = []
    StripeTransferExternallyToGumroad.stub :available_balances, { "usd" => -100, "cad" => 100 } do
      StripeTransferExternallyToGumroad.stub :transfer, ->(c, a) { calls << [c, a] } do
        StripeTransferExternallyToGumroad.transfer_all_available_balances
      end
    end
    assert_equal [["cad", 100]], calls
  end

  test "transfer_all_available_balances subtracts buffer from positive balances" do
    calls = []
    StripeTransferExternallyToGumroad.stub :available_balances, { "usd" => 100, "cad" => 200 } do
      StripeTransferExternallyToGumroad.stub :transfer, ->(c, a) { calls << [c, a] } do
        StripeTransferExternallyToGumroad.transfer_all_available_balances(buffer_cents: 50)
      end
    end
    assert_equal [["usd", 50], ["cad", 150]], calls
  end

  test "transfer_all_available_balances with buffer skips zero balance and uses buffer for positive" do
    calls = []
    StripeTransferExternallyToGumroad.stub :available_balances, { "usd" => 0, "cad" => 100 } do
      StripeTransferExternallyToGumroad.stub :transfer, ->(c, a) { calls << [c, a] } do
        StripeTransferExternallyToGumroad.transfer_all_available_balances(buffer_cents: 50)
      end
    end
    assert_equal [["cad", 50]], calls
  end

  test "transfer_all_available_balances with buffer skips negative balance" do
    calls = []
    StripeTransferExternallyToGumroad.stub :available_balances, { "usd" => -100, "cad" => 100 } do
      StripeTransferExternallyToGumroad.stub :transfer, ->(c, a) { calls << [c, a] } do
        StripeTransferExternallyToGumroad.transfer_all_available_balances(buffer_cents: 50)
      end
    end
    assert_equal [["cad", 50]], calls
  end
end
