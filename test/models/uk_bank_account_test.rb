require "test_helper"

class UkBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    UkBankAccount.new({
      user: users(:named_seller),
      account_number: "1234567",
      sort_code: "06-21-11",
      account_number_last_four: "4567",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "sort_code 6 digits with hyphens is valid" do
    assert build(sort_code: "06-21-11").valid?
  end

  test "sort_code nil is not valid" do
    assert_not build(sort_code: nil).valid?
  end

  test "sort_code 6 digits without hyphens is not valid" do
    assert_not build(sort_code: "123456").valid?
  end

  test "sort_code 5 digits is not valid" do
    assert_not build(sort_code: "12345").valid?
  end

  test "sort_code 7 digits with hyphens is not valid" do
    assert_not build(sort_code: "12-34-56-7").valid?
  end

  test "sort_code with alpha characters is not valid" do
    assert_not build(sort_code: "12-34-5a").valid?
  end

  test "routing_number is the sort_code" do
    assert_equal "45-37-80", build(sort_code: "45-37-80").routing_number
  end
end
