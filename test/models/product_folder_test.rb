require "test_helper"

class ProductFolderTest < ActiveSupport::TestCase
  test "validates presence of name" do
    folder = ProductFolder.new(name: "")
    refute folder.valid?
    assert_equal({ name: ["can't be blank"] }, folder.errors.messages)
  end
end
