# frozen_string_literal: true

require "test_helper"

ActiveRecord::Schema.define do
  create_table :unused_columns_test_models, temporary: true, force: true do |t|
    t.string :name
    t.string :email
    t.string :description
  end
end

class UnusedColumnsTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  class UnusedColumnsTestModel < ActiveRecord::Base
    self.table_name = "unused_columns_test_models"
    include UnusedColumns
    unused_columns :description
  end

  setup do
    @record = UnusedColumnsTestModel.new
  end

  test "raises NoMethodError when reading a value from an unused column" do
    error = assert_raises(NoMethodError) { @record.description }
    assert_equal "Column description is deprecated and no longer used.", error.message
  end

  test "raises NoMethodError when assigning a value to an unused column" do
    error = assert_raises(NoMethodError) { @record.description = "some value" }
    assert_equal "Column description is deprecated and no longer used.", error.message
  end

  test "returns unused attributes" do
    assert_equal ["description"], UnusedColumnsTestModel.unused_attributes
  end
end
