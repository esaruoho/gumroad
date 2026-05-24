require "test_helper"

class Purchase::CustomFieldsTest < ActiveSupport::TestCase
  setup do
    @purchase = purchases(:auto_invoice_enabled_purchase)
    @product = links(:named_seller_product)
    @seller = users(:named_seller)
  end

  test "invalidates the purchase when a custom field is invalid" do
    cf = CustomField.create!(name: "http://test", field_type: "terms", required: true, seller: @seller)
    @product.custom_fields << cf
    purchase = Purchase.new(seller: @seller, link: @product, price_cents: 100, email: "buyer@example.com")
    purchase.purchase_custom_fields << PurchaseCustomField.build_from_custom_field(custom_field: @product.custom_fields.first, value: false)
    assert purchase.invalid?
    assert_equal ["Value can't be blank"], purchase.purchase_custom_fields.first.errors.full_messages
    assert_includes purchase.errors.full_messages, "Purchase custom fields is invalid"
  end

  test "#custom_fields returns the custom field records when present" do
    @purchase.purchase_custom_fields << [
      PurchaseCustomField.new(name: "Text", value: "Value", field_type: CustomField::TYPE_TEXT),
      PurchaseCustomField.new(name: "Truthy", value: true, field_type: CustomField::TYPE_CHECKBOX),
      PurchaseCustomField.new(name: "Falsy", value: false, field_type: CustomField::TYPE_CHECKBOX),
      PurchaseCustomField.new(name: "http://terms", value: true, field_type: CustomField::TYPE_TERMS),
    ]
    assert_equal(
      [
        { name: "Text", value: "Value", type: CustomField::TYPE_TEXT },
        { name: "Truthy", value: true, type: CustomField::TYPE_CHECKBOX },
        { name: "Falsy", value: false, type: CustomField::TYPE_CHECKBOX },
        { name: "http://terms", value: true, type: CustomField::TYPE_TERMS },
      ],
      @purchase.custom_fields
    )
  end

  test "#custom_fields returns an empty array when there are no records" do
    purchase = purchases(:auto_invoice_no_billing_purchase)
    purchase.purchase_custom_fields.destroy_all
    assert_equal [], purchase.custom_fields
  end
end
