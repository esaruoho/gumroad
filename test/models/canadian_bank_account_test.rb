require "test_helper"

class CanadianBankAccountTest < ActiveSupport::TestCase
  def build(**attrs)
    CanadianBankAccount.new({
      user: users(:named_seller),
      account_number: "1234567",
      transit_number: "12345",
      institution_number: "123",
      account_number_last_four: "4567",
      account_holder_full_name: "Gumbot Gumstein I",
    }.merge(attrs))
  end

  test "transit_number is 5 digits is valid" do
    assert build(transit_number: "12345").valid?
  end

  test "transit_number nil is not valid" do
    assert_not build(transit_number: nil).valid?
  end

  test "transit_number is 4 digits is not valid" do
    assert_not build(transit_number: "1234").valid?
  end

  test "transit_number is 6 digits is not valid" do
    assert_not build(transit_number: "123456").valid?
  end

  test "transit_number contains alpha characters is not valid" do
    assert_not build(transit_number: "1234a").valid?
  end

  test "institution_number is 3 digits is valid" do
    assert build(institution_number: "123").valid?
  end

  test "institution_number nil is not valid" do
    assert_not build(institution_number: nil).valid?
  end

  test "institution_number is 2 digits is not valid" do
    assert_not build(institution_number: "12").valid?
  end

  test "institution_number is 4 digits is not valid" do
    assert_not build(institution_number: "1234").valid?
  end

  test "institution_number contains alpha characters is not valid" do
    assert_not build(institution_number: "12a").valid?
  end

  test "routing_number is a concat of institution_number, hyphen and transit_number" do
    ba = build(transit_number: "45678", institution_number: "123")
    assert_equal "45678-123", ba.routing_number
  end
end
