# frozen_string_literal: true

require "test_helper"

class MoneyFormatterTest < ActiveSupport::TestCase
  test "usd returns the correct string" do
    assert_equal "$4.00", MoneyFormatter.format(400, :usd)
  end

  test "usd returns correctly when no symbol desired" do
    assert_equal "4.00", MoneyFormatter.format(400, :usd, symbol: false)
  end

  test "jpy returns the correct string" do
    assert_equal "¥400", MoneyFormatter.format(400, :jpy)
  end

  test "aud returns the correct currency symbol" do
    assert_equal "A$4.00", MoneyFormatter.format(400, :aud)
  end
end
