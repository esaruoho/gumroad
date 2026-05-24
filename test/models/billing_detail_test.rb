require "test_helper"

class BillingDetailTest < ActiveSupport::TestCase
  setup do
    @user = users(:basic_user)
  end

  def build_billing_detail(**attrs)
    BillingDetail.new({
      purchaser: @user,
      full_name: "John Doe",
      business_name: "Acme Corporation",
      business_id: "DE123456789",
      street_address: "123 Main Street",
      city: "Berlin",
      zip_code: "10115",
      country_code: "DE",
    }.merge(attrs))
  end

  test "requires full_name, street_address, city, zip_code, country_code" do
    billing_detail = BillingDetail.new(purchaser: @user)
    assert_not billing_detail.valid?
    %i[full_name street_address city zip_code country_code].each do |attr|
      assert_includes billing_detail.errors[attr], "can't be blank"
    end
  end

  test "requires state when country is US" do
    billing_detail = BillingDetail.new(
      purchaser: @user,
      full_name: "Alice",
      street_address: "1 Market",
      city: "San Francisco",
      zip_code: "94107",
      country_code: "US",
    )
    assert_not billing_detail.valid?
    assert_includes billing_detail.errors[:state], "can't be blank"
  end

  test "does not require state when country is not US" do
    billing_detail = BillingDetail.new(
      purchaser: @user,
      full_name: "Alice",
      street_address: "1 Unter den Linden",
      city: "Berlin",
      zip_code: "10115",
      country_code: "DE",
    )
    assert billing_detail.valid?, billing_detail.errors.full_messages.to_sentence
  end

  test "validates country_code is a two-letter code" do
    billing_detail = build_billing_detail(country_code: "DEU")
    assert_not billing_detail.valid?
    assert_includes billing_detail.errors[:country_code], "is the wrong length (should be 2 characters)"
  end

  test "enforces one billing detail per purchaser" do
    build_billing_detail.save!
    duplicate = build_billing_detail
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:purchaser_id], "has already been taken"
  end

  test "#to_invoice_address_fields returns the address fields formatted for the invoice presenter" do
    billing_detail = build_billing_detail(
      state: "CA",
      country_code: "US",
      zip_code: "94107",
      city: "San Francisco",
    )
    assert_equal(
      {
        full_name: "John Doe",
        street_address: "123 Main Street",
        city: "San Francisco",
        state: "CA",
        zip_code: "94107",
        country_code: "US",
      },
      billing_detail.to_invoice_address_fields,
    )
  end

  test "defaults auto_email_invoice_enabled to true" do
    assert_equal true, BillingDetail.new.auto_email_invoice_enabled
  end

  test "is destroyed when the user is destroyed" do
    build_billing_detail.save!
    assert_difference -> { BillingDetail.count }, -1 do
      @user.destroy
    end
  end
end
