# frozen_string_literal: true

require "test_helper"

class CustomFieldTest < ActiveSupport::TestCase
  setup do
    @seller = users(:named_seller)
    @product = links(:named_seller_product)
  end

  test "#as_json returns the correct data" do
    field = CustomField.create!(seller: @seller, field_type: "text", name: "How tall?", products: [@product])
    assert_equal(
      {
        id: field.external_id,
        type: field.type,
        name: field.name,
        required: field.required,
        global: field.global,
        collect_per_product: field.collect_per_product,
        products: [@product.external_id],
      },
      field.as_json
    )
  end

  test "validates that the field name is a valid URI for terms fields" do
    field = CustomField.create!(seller: @seller, field_type: "text", name: "Custom field", global: true)
    field.update(field_type: "terms")
    assert_includes field.errors.full_messages, "Please provide a valid URL for custom field of Terms type."
  end

  test "disallows boolean fields for post-purchase custom fields" do
    field = CustomField.new(seller: @seller, name: "f", is_post_purchase: true, field_type: CustomField::TYPE_CHECKBOX)
    assert_not field.valid?
    assert_includes field.errors.full_messages, "Boolean post-purchase fields are not allowed"

    field.field_type = CustomField::TYPE_TERMS
    assert_not field.valid?
    assert_includes field.errors.full_messages, "Boolean post-purchase fields are not allowed"

    field.field_type = CustomField::TYPE_TEXT
    assert field.valid?, field.errors.full_messages.inspect
  end

  test "sets the default name for file fields" do
    file_field = CustomField.create!(seller: @seller, field_type: CustomField::TYPE_FILE, name: nil)
    assert_equal CustomField::FILE_FIELD_NAME, file_field.name
  end

  test "raises error when name is nil for non-file fields" do
    assert_raises(ActiveRecord::RecordInvalid) do
      CustomField.create!(seller: @seller, field_type: CustomField::TYPE_TEXT, name: nil)
    end
  end
end
