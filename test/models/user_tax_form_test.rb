# frozen_string_literal: true

require "test_helper"

class UserTaxFormTest < ActiveSupport::TestCase
  setup do
    @user = users(:purchaser)
  end

  test "belongs to user" do
    assoc = UserTaxForm.reflect_on_association(:user)
    assert_equal :belongs_to, assoc.macro
  end

  test "requires tax_year" do
    form = UserTaxForm.new(user: @user, tax_form_type: "us_1099_k")
    assert_not form.valid?
    assert_includes form.errors[:tax_year], "can't be blank"
  end

  test "tax_year is an integer >= MIN_TAX_YEAR" do
    form = UserTaxForm.new(user: @user, tax_form_type: "us_1099_k", tax_year: UserTaxForm::MIN_TAX_YEAR - 1)
    assert_not form.valid?
    assert_includes form.errors[:tax_year], "must be greater than or equal to #{UserTaxForm::MIN_TAX_YEAR}"

    form.tax_year = 2024.5
    assert_not form.valid?
    assert_includes form.errors[:tax_year], "must be an integer"
  end

  test "requires tax_form_type in TAX_FORM_TYPES" do
    form = UserTaxForm.new(user: @user, tax_year: 2024)
    assert_not form.valid?
    assert_includes form.errors[:tax_form_type], "can't be blank"

    form.tax_form_type = "bogus"
    assert_not form.valid?
    assert_includes form.errors[:tax_form_type], "is not included in the list"
  end

  test "user_id is unique per (tax_year, tax_form_type)" do
    UserTaxForm.create!(user: @user, tax_year: 2024, tax_form_type: "us_1099_k")
    dup = UserTaxForm.new(user: @user, tax_year: 2024, tax_form_type: "us_1099_k")
    assert_not dup.valid?
    assert_includes dup.errors[:user_id], "has already been taken"
  end

  test ".for_year returns tax forms for the specified year" do
    UserTaxForm.create!(user: @user, tax_year: 2022, tax_form_type: "us_1099_k")
    form_2023 = UserTaxForm.create!(user: @user, tax_year: 2023, tax_form_type: "us_1099_k")
    assert_equal [form_2023], UserTaxForm.for_year(2023).where(user_id: @user.id).to_a
  end
end
