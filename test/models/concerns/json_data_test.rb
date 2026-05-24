# frozen_string_literal: true

require "test_helper"

class JsonDataTest < ActiveSupport::TestCase
  # JsonData is included in many models; Purchase is the easiest concrete one.
  setup do
    @model = purchases(:auto_invoice_enabled_purchase)
  end

  # attr_json_data_reader
  test "attr_json_data_reader returns the value of the attribute" do
    @model.json_data = { "locale" => :en }
    assert_equal :en, @model.locale.to_sym
  end

  test "attr_json_data_reader returns the default value when attribute not set or blank" do
    @model.json_data = { "locale" => nil }
    assert_equal :en, @model.locale.to_sym
  end

  # attr_json_data_writer
  test "attr_json_data_writer sets the attribute in json_data" do
    @model.locale = :ja
    assert_equal :ja, @model.json_data["locale"].to_sym
  end

  # json_data
  test "json_data returns an empty hash if not initialized" do
    @model.json_data = nil
    assert_equal({}, @model.json_data)
  end

  # json_data_for_attr
  test "json_data_for_attr gets the attribute in json_data" do
    @model.json_data = { "attribute" => "hi" }
    assert_equal "hi", @model.json_data_for_attr("attribute", default: "default")
  end

  test "json_data_for_attr returns the default if json_data is nil" do
    @model.json_data = nil
    assert_equal "default", @model.json_data_for_attr("attribute", default: "default")
  end

  test "json_data_for_attr returns the default if the attribute does not exist in json_data" do
    @model.json_data = {}
    assert_equal "default", @model.json_data_for_attr("attribute", default: "default")
  end

  test "json_data_for_attr returns the default if the attribute does exist but is not present" do
    @model.json_data = { "attribute" => "" }
    assert_equal "default", @model.json_data_for_attr("attribute", default: "default")
  end

  test "json_data_for_attr returns the default if the attribute does exist but is nil" do
    @model.json_data = { "attribute" => nil }
    assert_equal "default", @model.json_data_for_attr("attribute", default: "default")
  end

  test "json_data_for_attr returns nil if the attribute does not exist in json_data and no default" do
    @model.json_data = {}
    assert_nil @model.json_data_for_attr("attribute")
  end

  # set_json_data_for_attr
  test "set_json_data_for_attr sets the attribute in json_data" do
    @model.set_json_data_for_attr("attribute", "hi")
    assert_equal "hi", @model.json_data["attribute"]
  end
end
