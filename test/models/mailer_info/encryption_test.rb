# frozen_string_literal: true

require "test_helper"

class MailerInfo::EncryptionTest < ActiveSupport::TestCase
  test ".encrypt returns nil for nil input" do
    assert_nil MailerInfo::Encryption.encrypt(nil)
  end

  test ".encrypt encrypts value with current key version" do
    encrypted = MailerInfo::Encryption.encrypt("test")
    assert encrypted.start_with?("v1:")
    assert_not_includes encrypted, "test"
    assert_equal 3, encrypted.split(":").size
  end

  test ".encrypt converts non-string values to string" do
    encrypted = MailerInfo::Encryption.encrypt(123)
    assert encrypted.start_with?("v1:")
    assert_equal "123", MailerInfo::Encryption.decrypt(encrypted)
  end

  test ".decrypt returns nil for nil input" do
    assert_nil MailerInfo::Encryption.decrypt(nil)
  end

  test ".decrypt decrypts encrypted value" do
    value = "test_value"
    encrypted = MailerInfo::Encryption.encrypt(value)
    assert_equal value, MailerInfo::Encryption.decrypt(encrypted)
  end

  test ".decrypt raises error for unknown key version" do
    error = assert_raises(RuntimeError) { MailerInfo::Encryption.decrypt("v999:abc:def") }
    assert_equal "Unknown key version: 999", error.message
  end

  test ".decrypt raises error for invalid format" do
    error = assert_raises(RuntimeError) { MailerInfo::Encryption.decrypt("invalid") }
    assert_equal "Unknown key version: 0", error.message
  end

  test "uses the highest version as current key" do
    stubbed_keys = { 1 => "key1", 2 => "key2", 3 => "key3" }
    MailerInfo::Encryption.stub(:encryption_keys, stubbed_keys) do
      encrypted = MailerInfo::Encryption.encrypt("test")
      assert encrypted.start_with?("v3:")
    end
  end
end
