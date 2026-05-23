# frozen_string_literal: true

require "test_helper"

class StripeMetadataTest < ActiveSupport::TestCase
  test "build_metadata_large_list returns a key-value pair hash of items" do
    items = %w[asdfasdf asdfasdfasdfasdf]
    assert_equal(
      { "myKey{0}" => "asdfasdf,asdfasdfasdfasdf" },
      StripeMetadata.build_metadata_large_list(items, key: "myKey")
    )
  end

  test "build_metadata_large_list converts symbol key to string" do
    items = %w[asdfasdf asdfasdfasdfasdf]
    assert_equal(
      { "my_key{0}" => "asdfasdf,asdfasdfasdfasdf" },
      StripeMetadata.build_metadata_large_list(items, key: :my_key)
    )
  end

  test "build_metadata_large_list splits a big list across multiple keys" do
    items = (1..99).map { |n| format("asdfasdf%.2i", n) }
    expected = {
      "myKey{0}" => "asdfasdf01,asdfasdf02,asdfasdf03,asdfasdf04,asdfasdf05,asdfasdf06,asdfasdf07,asdfasdf08,asdfasdf09," \
        "asdfasdf10,asdfasdf11,asdfasdf12,asdfasdf13,asdfasdf14,asdfasdf15,asdfasdf16,asdfasdf17,asdfasdf18," \
        "asdfasdf19,asdfasdf20,asdfasdf21,asdfasdf22,asdfasdf23,asdfasdf24,asdfasdf25,asdfasdf26,asdfasdf27," \
        "asdfasdf28,asdfasdf29,asdfasdf30,asdfasdf31,asdfasdf32,asdfasdf33,asdfasdf34,asdfasdf35,asdfasdf36," \
        "asdfasdf37,asdfasdf38,asdfasdf39,asdfasdf40,asdfasdf41,asdfasdf42,asdfasdf43,asdfasdf44,asdfasdf45",
      "myKey{1}" => "asdfasdf46,asdfasdf47,asdfasdf48,asdfasdf49,asdfasdf50,asdfasdf51,asdfasdf52,asdfasdf53,asdfasdf54," \
        "asdfasdf55,asdfasdf56,asdfasdf57,asdfasdf58,asdfasdf59,asdfasdf60,asdfasdf61,asdfasdf62,asdfasdf63," \
        "asdfasdf64,asdfasdf65,asdfasdf66,asdfasdf67,asdfasdf68,asdfasdf69,asdfasdf70,asdfasdf71,asdfasdf72," \
        "asdfasdf73,asdfasdf74,asdfasdf75,asdfasdf76,asdfasdf77,asdfasdf78,asdfasdf79,asdfasdf80,asdfasdf81," \
        "asdfasdf82,asdfasdf83,asdfasdf84,asdfasdf85,asdfasdf86,asdfasdf87,asdfasdf88,asdfasdf89,asdfasdf90",
      "myKey{2}" => "asdfasdf91,asdfasdf92,asdfasdf93,asdfasdf94,asdfasdf95,asdfasdf96,asdfasdf97,asdfasdf98,asdfasdf99"
    }
    assert_equal expected, StripeMetadata.build_metadata_large_list(items, key: "myKey")
  end

  test "build_metadata_large_list returns multiple key-value pairs with big items in each one" do
    big_item_1 =
      "asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01" \
      "asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01" \
      "asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01" \
      "asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01" \
      "asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01" \
      "asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01asdfasdf01"
    big_item_2 =
      "asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02" \
      "asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02" \
      "asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02" \
      "asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02" \
      "asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02" \
      "asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02asdfasdf02"
    assert_equal(
      { "myKey{0}" => big_item_1, "myKey{1}" => big_item_2 },
      StripeMetadata.build_metadata_large_list([big_item_1, big_item_2], key: "myKey")
    )
  end
end
