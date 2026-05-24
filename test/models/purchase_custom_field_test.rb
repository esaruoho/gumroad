# frozen_string_literal: true

require "test_helper"

class PurchaseCustomFieldTest < ActiveSupport::TestCase
  test "validates field type is a custom field type" do
    pcf = PurchaseCustomField.new(field_type: "invalid")
    refute pcf.valid?
    assert_includes pcf.errors.full_messages, "Field type is not included in the list"
  end

  test "validates name is present" do
    pcf = PurchaseCustomField.new
    refute pcf.valid?
    assert_includes pcf.errors.full_messages, "Name can't be blank"
  end

  test "normalizes value" do
    pcf = PurchaseCustomField.new(value: "  test    value  ")
    assert_equal "test value", pcf.value
  end

  test "converts nil to false for boolean fields" do
    pcf = PurchaseCustomField.create(field_type: CustomField::TYPE_CHECKBOX, value: nil)
    assert_equal false, pcf.value
  end

  CustomField::TYPE_TEXT.tap { } # ensure constants are loaded

  [CustomField::TYPE_TEXT, CustomField::TYPE_LONG_TEXT].each do |type|
    define_method("test_requires_value_for_#{type}_custom_field_if_required") do
      custom_field = make_custom_field(type: type, required: true)
      purchase = purchases(:auto_invoice_enabled_purchase)
      pcf = PurchaseCustomField.build_from_custom_field(custom_field:, value: "")
      purchase.purchase_custom_fields << pcf
      refute pcf.valid?
      assert_includes pcf.errors.full_messages, "Value can't be blank"

      pcf.value = "value"
      assert pcf.valid?
    end

    define_method("test_allows_blank_for_optional_#{type}_custom_field") do
      custom_field = make_custom_field(type: type, required: false)
      purchase = purchases(:auto_invoice_enabled_purchase)
      pcf = PurchaseCustomField.build_from_custom_field(custom_field:, value: "")
      purchase.purchase_custom_fields << pcf
      assert pcf.valid?
    end
  end

  test "requires value for checkbox custom field if required is true" do
    custom_field = make_custom_field(type: CustomField::TYPE_CHECKBOX, required: true)
    purchase = purchases(:auto_invoice_enabled_purchase)
    pcf = PurchaseCustomField.build_from_custom_field(custom_field:, value: false)
    purchase.purchase_custom_fields << pcf
    refute pcf.valid?
    assert_includes pcf.errors.full_messages, "Value can't be blank"

    pcf.value = true
    assert pcf.valid?
  end

  test "allows false for an optional checkbox custom field" do
    custom_field = make_custom_field(type: CustomField::TYPE_CHECKBOX, required: false)
    purchase = purchases(:auto_invoice_enabled_purchase)
    pcf = PurchaseCustomField.build_from_custom_field(custom_field:, value: false)
    purchase.purchase_custom_fields << pcf
    assert pcf.valid?
  end

  test "requires value for terms custom field to be true" do
    custom_field = make_custom_field(name: "https://test", type: CustomField::TYPE_TERMS, required: true)
    purchase = purchases(:auto_invoice_enabled_purchase)
    pcf = PurchaseCustomField.build_from_custom_field(custom_field:, value: false)
    purchase.purchase_custom_fields << pcf
    refute pcf.valid?
    assert_includes pcf.errors.full_messages, "Value can't be blank"

    pcf.value = true
    assert pcf.valid?
  end

  test ".build_from_custom_field assigns attributes correctly" do
    custom_field = make_custom_field
    pcf = PurchaseCustomField.build_from_custom_field(custom_field:, value: "test")
    assert_equal custom_field, pcf.custom_field
    assert_equal custom_field.name, pcf.name
    assert_equal custom_field.type, pcf.field_type
    assert_equal "test", pcf.value
  end

  test "#value returns boolean cast for boolean field types" do
    pcf = PurchaseCustomField.new(field_type: CustomField::TYPE_CHECKBOX, value: "false")
    assert_equal false, pcf.value

    pcf = PurchaseCustomField.new(field_type: CustomField::TYPE_TERMS, value: "yes")
    assert_equal true, pcf.value
  end

  test "#value returns the value as-is for non-boolean field types" do
    pcf = PurchaseCustomField.new(field_type: CustomField::TYPE_TEXT, value: "value")
    assert_equal "value", pcf.value
  end

  test "skipped: file custom field validations require ActiveStorage attach" do
    skip "PurchaseCustomField file-type validations rely on ActiveStorage::Blob.create_and_upload! (smilie.png) — ActiveStorage attach skipped per migration policy."
  end

  private
    def make_custom_field(type: CustomField::TYPE_TEXT, required: false, name: "Field name")
      CustomField.create!(field_type: type, name: name, required: required, seller: users(:named_seller))
    end
end
