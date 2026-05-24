# frozen_string_literal: true

require "test_helper"

class TagTest < ActiveSupport::TestCase
  setup do
    @product = links(:tag_test_product)
  end

  test "creates a new tag by name" do
    assert_not @product.has_tag?("bAdger")
    assert_difference -> { @product.tags.count }, 1 do
      @product.tag!("Badger")
    end
    assert_equal "badger", @product.tags.last.name
    assert @product.has_tag?("bAdGEr")
  end

  test "cleans tag name before save" do
    @product.tag!("  UP   space  ")
    assert_equal "up space", @product.tags.last.name
  end

  test "only cleans if name has changed" do
    tag = Tag.create!(name: "will be overwritten")
    tag.update_column(:name, "INVA  LID")
    tag.reload
    assert_equal "INVA  LID", tag.name
    tag.humanized_name = "invalid-human"
    tag.save!
    assert_equal "INVA  LID", tag.name
  end

  test "does not raise exception on tags without names" do
    assert_not Tag.new.valid?
  end

  test "must have name" do
    tag = Tag.new
    tag.name = nil
    assert_raises(ActiveRecord::RecordInvalid) { tag.save! }
  end

  test "must be unique regardless of case" do
    Tag.create!(name: "existing")
    assert_raises(ActiveRecord::RecordInvalid) { Tag.create!(name: "existing") }
    assert_raises(ActiveRecord::RecordInvalid) { Tag.create!(name: "EXISTING") }
  end

  test "checks for names longer than max allowed" do
    err = assert_raises(ActiveRecord::RecordInvalid) { Tag.create!(name: "12345678901234567890_") }
    assert_match(/A tag is too long/, err.message)
  end

  test "checks for names shorter than min allowed" do
    err = assert_raises(ActiveRecord::RecordInvalid) { Tag.create!(name: "a") }
    assert_match(/A tag is too short/, err.message)
  end

  test "disallows tags starting with hashes" do
    err = assert_raises(ActiveRecord::RecordInvalid) { Tag.create!(name: "#icon") }
    assert_match(/cannot start with hashes/, err.message)
  end

  test "disallows tags with commas" do
    err = assert_raises(ActiveRecord::RecordInvalid) { Tag.create!(name: ",icon") }
    assert_match(/cannot.* contain commas/, err.message)
  end

  test "tags with an existing tag by name does not create duplicate" do
    Tag.create!(name: "ocelot")
    assert_no_difference -> { Tag.count } do
      @product.tag!("Ocelot")
    end
    assert_equal "ocelot", @product.tags.last.name
  end

  test "lists tags for a product" do
    @product.tag!("otter")
    @product.tag!("brontosaurus")
    assert_equal %w[otter brontosaurus], @product.tags.map(&:name)
  end

  test "lists products for a tag" do
    @product.tag!("ottertag")
    second_product = links(:tag_test_product_two)
    second_product.tag!("ottertag")
    assert_equal [@product, second_product].sort, Tag.find_by(name: "ottertag").products.sort
  end

  test "flags" do
    tag = Tag.create!(name: "flagtest")
    assert_not tag.flagged?
    tag.flag!
    assert tag.flagged?
  end

  test "unflags" do
    tag = Tag.create!(name: "unflagtest", flagged_at: Time.current)
    assert tag.flagged?
    tag.unflag!
    assert_not tag.flagged?
  end

  test "#humanized_name capitalizes" do
    tag = Tag.create!(name: "photoshop tutorial")
    assert_equal "Photoshop Tutorial", tag.humanized_name
  end

  test "#humanized_name titleizes" do
    tag = Tag.create!(name: "raiders_of_stuff")
    assert_equal "Raiders Of Stuff", tag.humanized_name
  end

  test "untags" do
    3.times { |i| Tag.create!(name: "Some Tag #{i}") }
    @product.tag!("Wildebeest")
    assert @product.has_tag?("WILDEBEEST")
    @product.untag!("wIlDeBeeST")
    assert_equal 0, @product.tags.count
    assert_not @product.has_tag?("wildebeest")
  end
end
