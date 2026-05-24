# frozen_string_literal: true

require "test_helper"

class ComputedSalesAnalyticsDayTest < ActiveSupport::TestCase
  test "read_data_from_keys returns hash with sorted existing keys and parsed values" do
    ComputedSalesAnalyticsDay.create!(key: "k2", data: { v: 2 }.to_json)
    ComputedSalesAnalyticsDay.create!(key: "k0", data: { v: 0 }.to_json)
    result = ComputedSalesAnalyticsDay.read_data_from_keys(["k0", "k1", "k2"])
    expected = {
      "k0" => { "v" => 0 },
      "k1" => nil,
      "k2" => { "v" => 2 }
    }
    assert_equal expected.to_a, result.to_a
  end

  test "fetch_data_from_key creates record if the key does not exist, returns existing data if it does" do
    assert_difference -> { ComputedSalesAnalyticsDay.count }, 1 do
      result = ComputedSalesAnalyticsDay.fetch_data_from_key("k0") { { "v" => 0 } }
      assert_equal({ "v" => 0 }, result)
    end
    assert_no_difference -> { ComputedSalesAnalyticsDay.count } do
      result = ComputedSalesAnalyticsDay.fetch_data_from_key("k0") { { "v" => 1 } }
      assert_equal({ "v" => 0 }, result)
    end
  end

  test "upsert_data_from_key creates a record if it doesn't exist, update data if it does" do
    assert_difference -> { ComputedSalesAnalyticsDay.count }, 1 do
      ComputedSalesAnalyticsDay.upsert_data_from_key("k0", { "v" => 0 })
    end
    assert_equal({ "v" => 0 }.to_json, ComputedSalesAnalyticsDay.last.data)
    assert_no_difference -> { ComputedSalesAnalyticsDay.count } do
      ComputedSalesAnalyticsDay.upsert_data_from_key("k0", { "v" => 1 })
    end
    assert_equal({ "v" => 1 }.to_json, ComputedSalesAnalyticsDay.last.data)
  end
end
