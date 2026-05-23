# frozen_string_literal: true

require "test_helper"

class SecureEncryptServiceTest < ActiveSupport::TestCase
  setup do
    @key = SecureRandom.random_bytes(32)
    @text = "this is a secret message"
    @original_get = GlobalConfig.method(:get)
    GlobalConfig.define_singleton_method(:get) do |name, *args|
      name == "SECURE_ENCRYPT_KEY" ? @secure_test_key : nil
    end
    SecureEncryptService.instance_variable_set(:@secure_test_key, @key)
    GlobalConfig.instance_variable_set(:@secure_test_key, @key)
    SecureEncryptService.instance_variable_set(:@encryptor, nil)
  end

  teardown do
    GlobalConfig.singleton_class.send(:remove_method, :get) rescue nil
    GlobalConfig.define_singleton_method(:get, @original_get)
    SecureEncryptService.instance_variable_set(:@encryptor, nil)
  end

  def reset_key(new_key)
    GlobalConfig.instance_variable_set(:@secure_test_key, new_key)
    SecureEncryptService.instance_variable_set(:@encryptor, nil)
  end

  test "encrypt encrypts text" do
    encrypted = SecureEncryptService.encrypt(@text)
    refute_predicate encrypted, :blank?
    refute_equal @text, encrypted
  end

  test "decrypt decrypts text" do
    encrypted = SecureEncryptService.encrypt(@text)
    assert_equal @text, SecureEncryptService.decrypt(encrypted)
  end

  test "decrypt returns nil for tampered text" do
    encrypted = SecureEncryptService.encrypt(@text)
    assert_nil SecureEncryptService.decrypt(encrypted + "tamper")
  end

  test "decrypt returns nil for a different key" do
    encrypted_first = SecureEncryptService.encrypt(@text)
    reset_key(SecureRandom.random_bytes(32))
    assert_nil SecureEncryptService.decrypt(encrypted_first)
  end

  test "verify returns true for correct text" do
    encrypted = SecureEncryptService.encrypt(@text)
    assert_equal true, SecureEncryptService.verify(encrypted, @text)
  end

  test "verify returns false for incorrect text" do
    encrypted = SecureEncryptService.encrypt(@text)
    assert_equal false, SecureEncryptService.verify(encrypted, "wrong message")
  end

  test "verify returns false for tampered encrypted text" do
    encrypted = SecureEncryptService.encrypt(@text)
    assert_equal false, SecureEncryptService.verify(encrypted + "tamper", @text)
  end

  test "verify returns false for nil user input" do
    encrypted = SecureEncryptService.encrypt(@text)
    assert_equal false, SecureEncryptService.verify(encrypted, nil)
  end

  test "raises MissingKeyError if key is not set" do
    reset_key(nil)
    err = assert_raises(SecureEncryptService::MissingKeyError) { SecureEncryptService.encrypt(@text) }
    assert_equal "SECURE_ENCRYPT_KEY is not set.", err.message
  end

  test "raises InvalidKeyError if key is not 32 bytes" do
    reset_key("short_key")
    err = assert_raises(SecureEncryptService::InvalidKeyError) { SecureEncryptService.encrypt(@text) }
    assert_equal "SECURE_ENCRYPT_KEY must be 32 bytes for aes-256-gcm.", err.message
  end
end
