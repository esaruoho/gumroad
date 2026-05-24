# frozen_string_literal: true

require "test_helper"

class SecureExternalIdTest < ActiveSupport::TestCase
  # Build a fresh anonymous test class (with its own @config / @encryptors caches) per test.
  def build_test_class
    Class.new do
      include SecureExternalId

      def self.name
        "TestClass"
      end

      def self.find_by(conditions)
        new if conditions[:id] == 123
      end

      def id
        123
      end
    end
  end

  # Returns a lambda that mimics RSpec's `allow(GlobalConfig).to receive(:dig).with(...).and_return(...)`.
  # `responses` is an array of [args_array, return_value] pairs (or [args, kwargs, return_value]).
  def build_dig_stub(mapping)
    ->(*args, **opts) {
      # Match by full args + kwargs
      mapping.each do |pattern_args, pattern_kwargs, ret|
        if args == pattern_args && opts == pattern_kwargs
          return ret
        end
      end
      nil
    }
  end

  def with_global_config_dig(mapping, &block)
    # We use a class instance variable to hold the active mapping so that the
    # stub can be installed exactly once per test (avoiding nested-stub alias
    # breakage in Minitest where re-aliasing __minitest_stub__dig drops the
    # original method on unwind).
    self.class.instance_variable_set(:@current_mapping, mapping)
    if self.class.instance_variable_get(:@global_config_dig_stubbed)
      # Already inside an outer stub — just swap the mapping and yield.
      block.call
    else
      self.class.instance_variable_set(:@global_config_dig_stubbed, true)
      stub_proc = ->(*args, **opts) do
        mp = self.class.instance_variable_get(:@current_mapping) || []
        mp.each do |pattern_args, pattern_kwargs, ret|
          return ret if args == pattern_args && opts == pattern_kwargs
        end
        nil
      end
      begin
        GlobalConfig.stub(:dig, stub_proc, &block)
      ensure
        self.class.instance_variable_set(:@global_config_dig_stubbed, false)
        self.class.instance_variable_set(:@current_mapping, nil)
      end
    end
  end

  STANDARD_MAPPING = [
    [[:secure_external_id], { default: nil }, { primary_key_version: "1", keys: { "1" => "a" * 32 } }]
  ].freeze

  setup do
    @test_class = build_test_class
    @test_instance = @test_class.new
  end

  # #secure_external_id
  test "#secure_external_id generates an encrypted token" do
    with_global_config_dig(STANDARD_MAPPING) do
      token = @test_instance.secure_external_id(scope: "test")
      assert_kind_of String, token
      assert token.length >= 50
    end
  end

  # .find_by_secure_external_id
  test ".find_by_secure_external_id finds record with valid token" do
    with_global_config_dig(STANDARD_MAPPING) do
      token = @test_instance.secure_external_id(scope: "test")
      assert_kind_of @test_class, @test_class.find_by_secure_external_id(token, scope: "test")
    end
  end

  test ".find_by_secure_external_id returns nil for invalid token" do
    with_global_config_dig(STANDARD_MAPPING) do
      assert_nil @test_class.find_by_secure_external_id("invalid", scope: "test")
    end
  end

  test ".find_by_secure_external_id returns nil for wrong scope" do
    with_global_config_dig(STANDARD_MAPPING) do
      token = @test_instance.secure_external_id(scope: "test")
      assert_nil @test_class.find_by_secure_external_id(token, scope: "wrong")
    end
  end

  test ".find_by_secure_external_id checks for expired token" do
    with_global_config_dig(STANDARD_MAPPING) do
      expires_at = 1.hour.from_now
      token = @test_instance.secure_external_id(scope: "test", expires_at: expires_at)

      travel_to 45.minutes.from_now do
        assert_kind_of @test_class, @test_class.find_by_secure_external_id(token, scope: "test")
      end

      travel_to 2.hours.from_now do
        assert_nil @test_class.find_by_secure_external_id(token, scope: "test")
      end
    end
  end

  test ".find_by_secure_external_id returns nil for non-string input" do
    with_global_config_dig(STANDARD_MAPPING) do
      assert_nil @test_class.find_by_secure_external_id(123, scope: "test")
    end
  end

  test ".find_by_secure_external_id returns nil for invalid base64" do
    with_global_config_dig(STANDARD_MAPPING) do
      assert_nil @test_class.find_by_secure_external_id("invalid base64!", scope: "test")
    end
  end

  test ".find_by_secure_external_id returns nil for tokens with invalid UTF-8 encoding" do
    with_global_config_dig(STANDARD_MAPPING) do
      invalid_utf8_token = Base64.urlsafe_encode64("{\"v\":\"1\",\"d\":\"|Y\xB8\"}")
      assert_nil @test_class.find_by_secure_external_id(invalid_utf8_token, scope: "test")
    end
  end

  test ".find_by_secure_external_id returns nil for wrong model name" do
    with_global_config_dig(STANDARD_MAPPING) do
      other_class = Class.new do
        include SecureExternalId
        def self.name; "OtherClass"; end
        def id; 123; end
      end

      token = @test_instance.secure_external_id(scope: "test")
      assert_nil other_class.find_by_secure_external_id(token, scope: "test")
    end
  end

  test ".find_by_secure_external_id supports key rotation" do
    with_global_config_dig(STANDARD_MAPPING) do
      token_v1 = @test_instance.secure_external_id(scope: "test")

      # Switch config to rotation set, reset memoized caches on the class.
      rotation_mapping = [
        [[:secure_external_id], { default: nil }, { primary_key_version: "2", keys: { "1" => "a" * 32, "2" => "b" * 32 } }]
      ]
      @test_class.instance_variable_set(:@config, nil)
      @test_class.instance_variable_set(:@encryptors, nil)

      with_global_config_dig(rotation_mapping) do
        assert_kind_of @test_class, @test_class.find_by_secure_external_id(token_v1, scope: "test")

        token_v2 = @test_instance.secure_external_id(scope: "test")
        assert_kind_of @test_class, @test_class.find_by_secure_external_id(token_v2, scope: "test")
      end
    end
  end

  # configuration validation
  test "configuration validation raises when configuration is blank" do
    mapping = [[[:secure_external_id], { default: nil }, {}]]
    with_global_config_dig(mapping) do
      err = assert_raises(SecureExternalId::Error) { @test_instance.secure_external_id(scope: "test") }
      assert_equal "SecureExternalId configuration is missing", err.message
    end
  end

  test "configuration validation raises when primary_key_version is missing" do
    mapping = [[[:secure_external_id], { default: nil }, { keys: { "1" => "a" * 32 } }]]
    with_global_config_dig(mapping) do
      err = assert_raises(SecureExternalId::Error) { @test_instance.secure_external_id(scope: "test") }
      assert_equal "primary_key_version is required in SecureExternalId config", err.message
    end
  end

  test "configuration validation raises when primary_key_version is blank" do
    mapping = [[[:secure_external_id], { default: nil }, { primary_key_version: "", keys: { "1" => "a" * 32 } }]]
    with_global_config_dig(mapping) do
      err = assert_raises(SecureExternalId::Error) { @test_instance.secure_external_id(scope: "test") }
      assert_equal "primary_key_version is required in SecureExternalId config", err.message
    end
  end

  test "configuration validation raises when keys are missing" do
    mapping = [[[:secure_external_id], { default: nil }, { primary_key_version: "1" }]]
    with_global_config_dig(mapping) do
      err = assert_raises(SecureExternalId::Error) { @test_instance.secure_external_id(scope: "test") }
      assert_equal "keys are required in SecureExternalId config", err.message
    end
  end

  test "configuration validation raises when keys are blank" do
    mapping = [[[:secure_external_id], { default: nil }, { primary_key_version: "1", keys: {} }]]
    with_global_config_dig(mapping) do
      err = assert_raises(SecureExternalId::Error) { @test_instance.secure_external_id(scope: "test") }
      assert_equal "keys are required in SecureExternalId config", err.message
    end
  end

  test "configuration validation raises when primary key version is not found in keys" do
    mapping = [[[:secure_external_id], { default: nil }, { primary_key_version: "2", keys: { "1" => "a" * 32 } }]]
    with_global_config_dig(mapping) do
      err = assert_raises(SecureExternalId::Error) { @test_instance.secure_external_id(scope: "test") }
      assert_equal "Primary key version '2' not found in keys", err.message
    end
  end

  test "configuration validation raises when key is not exactly 32 bytes" do
    mapping = [[[:secure_external_id], { default: nil }, { primary_key_version: "1", keys: { "1" => "short_key" } }]]
    with_global_config_dig(mapping) do
      err = assert_raises(SecureExternalId::Error) { @test_instance.secure_external_id(scope: "test") }
      assert_equal "Key for version '1' must be exactly 32 bytes for aes-256-gcm", err.message
    end
  end

  test "configuration validation raises when any key in rotation is not exactly 32 bytes" do
    mapping = [[[:secure_external_id], { default: nil }, { primary_key_version: "1", keys: { "1" => "a" * 32, "2" => "too_short" } }]]
    with_global_config_dig(mapping) do
      err = assert_raises(SecureExternalId::Error) { @test_instance.secure_external_id(scope: "test") }
      assert_equal "Key for version '2' must be exactly 32 bytes for aes-256-gcm", err.message
    end
  end

  test "configuration validation passes with proper configuration" do
    mapping = [[[:secure_external_id], { default: nil }, { primary_key_version: "1", keys: { "1" => "a" * 32, "2" => "b" * 32 } }]]
    with_global_config_dig(mapping) do
      # Should not raise
      @test_instance.secure_external_id(scope: "test")
    end
  end

  # environment variable configuration (credentials not present, falls back to env-style dig)
  def env_config_mapping(primary_version: "1", keys: { "1" => "a" * 32 })
    mapping = [
      [[:secure_external_id], { default: nil }, nil],
      [[:secure_external_id, :primary_key_version], { default: nil }, primary_version],
    ]
    (1..10).each do |version|
      mapping << [[:secure_external_id, :keys, version.to_s], { default: nil }, keys[version.to_s]]
    end
    mapping
  end

  test "env-var config builds config from environment variables" do
    with_global_config_dig(env_config_mapping) do
      token = @test_instance.secure_external_id(scope: "test")
      assert_kind_of String, token
      assert_kind_of @test_class, @test_class.find_by_secure_external_id(token, scope: "test")
    end
  end

  test "env-var config builds config with multiple key versions" do
    with_global_config_dig(env_config_mapping(primary_version: "2", keys: { "1" => "a" * 32, "2" => "b" * 32 })) do
      token = @test_instance.secure_external_id(scope: "test")
      assert_kind_of String, token
      assert_kind_of @test_class, @test_class.find_by_secure_external_id(token, scope: "test")
    end
  end

  test "env-var config supports key rotation" do
    with_global_config_dig(env_config_mapping) do
      token_v1 = @test_instance.secure_external_id(scope: "test")

      @test_class.instance_variable_set(:@config, nil)
      @test_class.instance_variable_set(:@encryptors, nil)

      with_global_config_dig(env_config_mapping(primary_version: "2", keys: { "1" => "a" * 32, "2" => "b" * 32 })) do
        assert_kind_of @test_class, @test_class.find_by_secure_external_id(token_v1, scope: "test")
        token_v2 = @test_instance.secure_external_id(scope: "test")
        assert_kind_of @test_class, @test_class.find_by_secure_external_id(token_v2, scope: "test")
      end
    end
  end

  test "env-var config raises error when primary_key_version is missing" do
    with_global_config_dig(env_config_mapping(primary_version: nil, keys: {})) do
      err = assert_raises(SecureExternalId::Error) { @test_instance.secure_external_id(scope: "test") }
      assert_equal "SecureExternalId configuration is missing", err.message
    end
  end

  test "env-var config raises error when primary_key_version is blank" do
    with_global_config_dig(env_config_mapping(primary_version: "", keys: {})) do
      err = assert_raises(SecureExternalId::Error) { @test_instance.secure_external_id(scope: "test") }
      assert_equal "SecureExternalId configuration is missing", err.message
    end
  end
end
