# frozen_string_literal: true

require "test_helper"

class Product::SavePostPurchaseCustomFieldsServiceTest < ActiveSupport::TestCase
  HAS_SAME_RICH_CONTENT_FOR_ALL_VARIANTS_FLAG = 2**24

  test "syncs post-purchase custom fields with product rich content nodes" do
    product = links(:rich_contents_product)
    enable_same_rich_content_for_all_variants(product)
    rich_contents(:rich_contents_product_page3).update_columns(deleted_at: Time.current)

    long_answer = create_custom_field(product:, field_type: CustomField::TYPE_LONG_TEXT, is_post_purchase: true)
    short_answer = create_custom_field(product:, field_type: CustomField::TYPE_TEXT, is_post_purchase: true)
    non_post_purchase = create_custom_field(product:, field_type: CustomField::TYPE_TEXT, is_post_purchase: false)
    rich_content = rich_contents(:rich_contents_product_page1)
    rich_content.update_columns(description: rich_content_description(long_answer:, non_post_purchase:, label_suffix: nil))

    assert_difference -> { product.custom_fields.is_post_purchase.count }, 2 do
      Product::SavePostPurchaseCustomFieldsService.new(product.reload).perform
    end

    assert_not CustomField.exists?(short_answer.id)
    assert_equal "Long answer", long_answer.reload.name
    assert_equal "Custom field", non_post_purchase.reload.name

    file_upload = product.custom_fields.is_post_purchase.find_by!(field_type: CustomField::TYPE_FILE)
    new_short_answer = product.custom_fields.is_post_purchase.find_by!(field_type: CustomField::TYPE_TEXT, name: "New short answer")
    other_new_short_answer = product.custom_fields.is_post_purchase.find_by!(field_type: CustomField::TYPE_TEXT, name: "Non post purchase short answer")

    assert_post_purchase_field(file_upload, product)
    assert_post_purchase_field(new_short_answer, product)
    assert_post_purchase_field(other_new_short_answer, product)
    assert_equal expected_rich_content_description(long_answer:, file_upload:, new_short_answer:, other_new_short_answer:, label_suffix: nil), rich_content.reload.description
  end

  test "syncs post-purchase custom fields with variant rich content nodes" do
    product = links(:rich_contents_variant_product)
    disable_same_rich_content_for_all_variants(product)
    rich_contents(:rich_contents_variant_page3).update_columns(deleted_at: Time.current)

    long_answer = create_custom_field(product:, field_type: CustomField::TYPE_LONG_TEXT, is_post_purchase: true)
    short_answer = create_custom_field(product:, field_type: CustomField::TYPE_TEXT, is_post_purchase: true)
    non_post_purchase = create_custom_field(product:, field_type: CustomField::TYPE_TEXT, is_post_purchase: false)
    rich_content1 = rich_contents(:rich_contents_variant_page1)
    rich_content2 = rich_contents(:rich_contents_other_variant_page)
    rich_content1.update_columns(description: rich_content_description(long_answer:, non_post_purchase:, label_suffix: " 1"))
    rich_content2.update_columns(description: rich_content_description_without_long_answer(non_post_purchase:, label_suffix: " 2"))

    assert_difference -> { product.custom_fields.is_post_purchase.count }, 5 do
      Product::SavePostPurchaseCustomFieldsService.new(product.reload).perform
    end

    assert_not CustomField.exists?(short_answer.id)
    assert_equal "Long answer 1", long_answer.reload.name
    assert_equal "Custom field", non_post_purchase.reload.name

    file_upload1 = product.custom_fields.is_post_purchase.where(field_type: CustomField::TYPE_FILE).first
    new_short_answer1 = product.custom_fields.is_post_purchase.find_by!(field_type: CustomField::TYPE_TEXT, name: "New short answer 1")
    other_new_short_answer1 = product.custom_fields.is_post_purchase.find_by!(field_type: CustomField::TYPE_TEXT, name: "Non post purchase short answer 1")
    file_upload2 = product.custom_fields.is_post_purchase.where(field_type: CustomField::TYPE_FILE).second
    new_short_answer2 = product.custom_fields.is_post_purchase.find_by!(field_type: CustomField::TYPE_TEXT, name: "New short answer 2")
    other_new_short_answer2 = product.custom_fields.is_post_purchase.find_by!(field_type: CustomField::TYPE_TEXT, name: "Non post purchase short answer 2")

    [file_upload1, new_short_answer1, other_new_short_answer1, file_upload2, new_short_answer2, other_new_short_answer2].each do |field|
      assert_post_purchase_field(field, product)
    end
    assert_equal expected_rich_content_description(long_answer:, file_upload: file_upload1, new_short_answer: new_short_answer1, other_new_short_answer: other_new_short_answer1, label_suffix: " 1"), rich_content1.reload.description
    assert_equal expected_rich_content_description_without_long_answer(file_upload: file_upload2, new_short_answer: new_short_answer2, other_new_short_answer: other_new_short_answer2, label_suffix: " 2"), rich_content2.reload.description
  end

  private
    def create_custom_field(product:, field_type:, is_post_purchase:)
      CustomField.create!(
        seller: product.user,
        products: [product],
        field_type:,
        name: "Custom field",
        is_post_purchase:,
      )
    end

    def enable_same_rich_content_for_all_variants(product)
      product.update_columns(flags: product.flags | HAS_SAME_RICH_CONTENT_FOR_ALL_VARIANTS_FLAG)
    end

    def disable_same_rich_content_for_all_variants(product)
      product.update_columns(flags: product.flags & ~HAS_SAME_RICH_CONTENT_FOR_ALL_VARIANTS_FLAG)
    end

    def rich_content_description(long_answer:, non_post_purchase:, label_suffix:)
      [
        { "type" => RichContent::LONG_ANSWER_NODE_TYPE, "attrs" => { "id" => long_answer.external_id, "label" => "Long answer#{label_suffix}" } },
        { "type" => RichContent::FILE_UPLOAD_NODE_TYPE },
        { "type" => RichContent::SHORT_ANSWER_NODE_TYPE, "attrs" => { "label" => "New short answer#{label_suffix}" } },
        { "type" => RichContent::SHORT_ANSWER_NODE_TYPE, "attrs" => { "id" => non_post_purchase.external_id, "label" => "Non post purchase short answer#{label_suffix}" } },
      ]
    end

    def rich_content_description_without_long_answer(non_post_purchase:, label_suffix:)
      [
        { "type" => RichContent::FILE_UPLOAD_NODE_TYPE },
        { "type" => RichContent::SHORT_ANSWER_NODE_TYPE, "attrs" => { "label" => "New short answer#{label_suffix}" } },
        { "type" => RichContent::SHORT_ANSWER_NODE_TYPE, "attrs" => { "id" => non_post_purchase.external_id, "label" => "Non post purchase short answer#{label_suffix}" } },
      ]
    end

    def expected_rich_content_description(long_answer:, file_upload:, new_short_answer:, other_new_short_answer:, label_suffix:)
      [
        { "type" => RichContent::LONG_ANSWER_NODE_TYPE, "attrs" => { "id" => long_answer.external_id, "label" => "Long answer#{label_suffix}" } },
        { "type" => RichContent::FILE_UPLOAD_NODE_TYPE, "attrs" => { "id" => file_upload.external_id } },
        { "type" => RichContent::SHORT_ANSWER_NODE_TYPE, "attrs" => { "label" => "New short answer#{label_suffix}", "id" => new_short_answer.external_id } },
        { "type" => RichContent::SHORT_ANSWER_NODE_TYPE, "attrs" => { "id" => other_new_short_answer.external_id, "label" => "Non post purchase short answer#{label_suffix}" } },
      ]
    end

    def expected_rich_content_description_without_long_answer(file_upload:, new_short_answer:, other_new_short_answer:, label_suffix:)
      [
        { "type" => RichContent::FILE_UPLOAD_NODE_TYPE, "attrs" => { "id" => file_upload.external_id } },
        { "type" => RichContent::SHORT_ANSWER_NODE_TYPE, "attrs" => { "label" => "New short answer#{label_suffix}", "id" => new_short_answer.external_id } },
        { "type" => RichContent::SHORT_ANSWER_NODE_TYPE, "attrs" => { "id" => other_new_short_answer.external_id, "label" => "Non post purchase short answer#{label_suffix}" } },
      ]
    end

    def assert_post_purchase_field(field, product)
      assert_equal product.user, field.seller
      assert_equal [product], field.products.to_a
      assert_predicate field, :is_post_purchase?
    end
end
