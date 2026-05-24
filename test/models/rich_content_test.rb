# frozen_string_literal: true

require "test_helper"

class RichContentTest < ActiveSupport::TestCase
  setup do
    @product = links(:basic_user_product)
  end

  # ----- validations -----

  test "adds error when the description is invalid" do
    [
      "not valid",
      ["also not valid"],
      [{ "type" => 2 }],
    ].each do |invalid_description|
      rich_content = RichContent.new(entity: @product, description: invalid_description)
      assert_not rich_content.valid?, "expected #{invalid_description.inspect} to be invalid"
      assert_equal ["Content is invalid"], rich_content.errors.full_messages
    end
  end

  test "does not add errors for valid descriptions" do
    [
      [],
      [{ "type": "text", "text": "Trace" }],
      [{ "type": "text", "text": "Trace" }, { "type": "text", "marks": [{ "type": "italic" }], "text": "Q" }],
    ].each do |valid_description|
      rich_content = RichContent.new(entity: @product, description: valid_description)
      assert rich_content.valid?, "expected #{valid_description.inspect} to be valid: #{rich_content.errors.full_messages.inspect}"
    end
  end

  # ----- #embedded_product_file_ids_in_order -----

  test "#embedded_product_file_ids_in_order returns the ids of the embedded product files in order" do
    file1 = @product.product_files.create!(url: "#{S3_BASE_URL}specs/rc_audio_1.mp3", position: 0)
    file2 = @product.product_files.create!(url: "#{S3_BASE_URL}specs/rc_file_2.bin", position: 1, created_at: 2.days.ago)
    file3 = @product.product_files.create!(url: "#{S3_BASE_URL}specs/rc_doc_3.pdf", position: 2)
    file4 = @product.product_files.create!(url: "#{S3_BASE_URL}specs/rc_video_4.mp4", position: 3, created_at: 1.day.ago)
    file5 = @product.product_files.create!(url: "#{S3_BASE_URL}specs/rc_audio_5.mp3", position: 4, created_at: 3.days.ago)

    rich_content = RichContent.create!(entity: @product, description: [
      { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Hello" }] },
      { "type" => "image", "attrs" => { "src" => "https://example.com/album.jpg", "link" => nil } },
      { "type" => "fileEmbed", "attrs" => { "id" => file2.external_id, "uid" => SecureRandom.uuid } },
      { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "World" }] },
      { "type" => "blockquote", "content" => [
        { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Inside blockquote" }] },
        { "type" => "fileEmbed", "attrs" => { "id" => file5.external_id, "uid" => SecureRandom.uuid } },
      ] },
      { "type" => "orderedList", "content" => [
        { "type" => "listItem", "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Ordered list item 1" }] }] },
        { "type" => "listItem", "content" => [
          { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Ordered list item 2" }] },
          { "type" => "fileEmbed", "attrs" => { "id" => file1.external_id, "uid" => SecureRandom.uuid } },
        ] },
        { "type" => "listItem", "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Ordered list item 3" }] }] },
      ] },
      { "type" => "bulletList", "content" => [
        { "type" => "listItem", "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Bullet list item 1" }] }] },
        { "type" => "listItem", "content" => [
          { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Bullet list item 2" }] },
          { "type" => "fileEmbed", "attrs" => { "id" => file4.external_id, "uid" => SecureRandom.uuid } },
        ] },
        { "type" => "listItem", "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Bullet list item 3" }] }] },
      ] },
      { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Lorem ipsum" }] },
      { "type" => "fileEmbed", "attrs" => { "id" => file3.external_id, "uid" => SecureRandom.uuid } },
    ])

    assert_equal [file2.id, file5.id, file1.id, file4.id, file3.id],
                 rich_content.embedded_product_file_ids_in_order
  end

  # ----- #has_license_key? -----

  test "#has_license_key? returns false if it does not contain license key" do
    rc = RichContent.create!(entity: @product, description: [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Hello" }] }])
    assert_equal false, rc.has_license_key?
  end

  test "#has_license_key? returns true if it contains license key" do
    rc = RichContent.create!(entity: @product, description: [{ "type" => "licenseKey" }])
    assert_equal true, rc.has_license_key?
  end

  test "#has_license_key? returns true if it contains license key nested inside a list item" do
    rc = RichContent.create!(entity: @product, description: [{ "type" => "orderedList", "content" => [{ "type" => "listItem", "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Ordered list item 2" }] }, { "type" => "licenseKey" }] }] }])
    assert_equal true, rc.has_license_key?
  end

  test "#has_license_key? returns true if it contains license key nested inside a blockquote" do
    rc = RichContent.create!(entity: @product, description: [{ "type" => "blockquote", "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Inside blockquote" }] }, { "type" => "licenseKey" }] }])
    assert_equal true, rc.has_license_key?
  end

  # ----- #has_posts? -----

  test "#has_posts? returns false if it does not contain posts" do
    rc = RichContent.create!(entity: @product, description: [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Hello" }] }])
    assert_equal false, rc.has_posts?
  end

  test "#has_posts? returns true if it contains posts" do
    rc = RichContent.create!(entity: @product, description: [{ "type" => "posts" }])
    assert_equal true, rc.has_posts?
  end

  test "#has_posts? returns true if it contains posts nested inside a list item" do
    rc = RichContent.create!(entity: @product, description: [{ "type" => "orderedList", "content" => [{ "type" => "listItem", "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Ordered list item 2" }] }, { "type" => "posts" }] }] }])
    assert_equal true, rc.has_posts?
  end

  test "#has_posts? returns true if it contains posts nested inside a blockquote" do
    rc = RichContent.create!(entity: @product, description: [{ "type" => "blockquote", "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Inside blockquote" }] }, { "type" => "posts" }] }])
    assert_equal true, rc.has_posts?
  end

  # The original spec also exercised a `reset_moderated_by_iffy_flag` callback on
  # save. That callback has since been removed (Link.flags bit 32 is now
  # `:DEPRECATED_moderated_by_iffy` and the callback chain in RichContent no
  # longer references it). Nothing to port for those three contexts.
end
