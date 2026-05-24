require "test_helper"

class StrippedFieldsTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  TABLE_NAME = "stripped_fields_test"

  setup do
    ActiveRecord::Schema.define do
      create_table StrippedFieldsTest::TABLE_NAME, force: true do |t|
        t.string :name
        t.string :email
        t.string :description
        t.string :sql
        t.string :code
      end
    end

    @test_model = Class.new(ApplicationRecord) do
      self.table_name = StrippedFieldsTest::TABLE_NAME

      include StrippedFields

      stripped_fields :name, :email, transform: ->(v) { v&.upcase }
      stripped_fields :description, nilify_blanks: false
      stripped_fields :sql, remove_duplicate_spaces: false
      stripped_fields :code, transform: ->(v) { v&.gsub(/\s/, "") }
    end
  end

  teardown do
    ActiveRecord::Schema.define do
      drop_table StrippedFieldsTest::TABLE_NAME, if_exists: true
    end
  end

  def build_record
    @test_model.new(
      name: "  my   name ",
      email: "   ",
      description: " ",
      sql: "  keep  extra  spaces   ",
      code: " 1234 56\n78 "
    )
  end

  test "applies transform and default blank nilification" do
    record = build_record
    record.validate

    assert_equal "MY NAME", record.name
    assert_nil record.email
  end

  test "keeps blank strings when nilify_blanks is false" do
    record = build_record
    record.validate

    assert_equal "", record.description
  end

  test "preserves duplicate spaces when remove_duplicate_spaces is false" do
    record = build_record
    record.validate

    assert_equal "keep  extra  spaces", record.sql
  end

  test "applies custom transform for code" do
    record = build_record
    record.validate

    assert_equal "12345678", record.code
  end
end
