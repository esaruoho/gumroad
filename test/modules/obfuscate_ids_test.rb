# frozen_string_literal: true

require "test_helper"

class ObfuscateIdsTest < ActiveSupport::TestCase
  test "decrypts the id correctly" do
    raw_id = Faker::Number.number(digits: 10)
    encrypted_id = ObfuscateIds.encrypt(raw_id)
    refute_equal raw_id.to_s, encrypted_id

    encrypted_id_without_padding = ObfuscateIds.encrypt(raw_id, padding: false)
    refute_equal raw_id.to_s, encrypted_id_without_padding

    assert_equal raw_id, ObfuscateIds.decrypt(encrypted_id)
    assert_equal raw_id, ObfuscateIds.decrypt(encrypted_id_without_padding)
  end

  test "numeric encryption decrypts the id correctly" do
    raw_id = rand(1..2**30)
    encrypted_id = ObfuscateIds.encrypt_numeric(raw_id)
    refute_equal raw_id.to_s, encrypted_id
    assert_equal raw_id, ObfuscateIds.decrypt_numeric(encrypted_id)
  end

  test "numeric encryption raises an error if the id is greater than the max value" do
    assert_raises(ArgumentError) { ObfuscateIds.encrypt_numeric(2**30) }
  end
end
