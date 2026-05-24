require "test_helper"

class AustralianBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    AustralianBankAccount.new({
      user: users(:named_seller),
      account_number: "1234567",
      bsb_number: "062111",
      account_number_last_four: "4567",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "bsb_number with 6 digits is valid" do
    assert build(bsb_number: "062111").valid?
  end

  test "bsb_number nil is not valid" do
    assert_not build(bsb_number: nil).valid?
  end

  test "bsb_number with 5 digits is not valid" do
    assert_not build(bsb_number: "12345").valid?
  end

  test "bsb_number with 7 digits is not valid" do
    assert_not build(bsb_number: "1234567").valid?
  end

  test "bsb_number containing alpha characters is not valid" do
    assert_not build(bsb_number: "12345a").valid?
  end

  test "routing_number is the bsb_number" do
    assert_equal "453780", build(bsb_number: "453780").routing_number
  end
end
