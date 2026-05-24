# frozen_string_literal: true

require "test_helper"

class ContentModeration::Strategies::BlocklistStrategyTest < ActiveSupport::TestCase
  Strategy = ContentModeration::Strategies::BlocklistStrategy

  setup do
    Strategy.reset_yaml_cache!

    @gc_class = GlobalConfig.singleton_class
    @original_gc_get = @gc_class.instance_method(:get)
    overrides = {}
    @overrides = overrides
    original = @original_gc_get
    @gc_class.define_method(:get) do |*args, **kwargs, &block|
      key = args.first
      overrides.key?(key) ? overrides[key] : original.bind(self).call(*args, **kwargs, &block)
    end

    # Stub yaml_words directly to avoid touching File/YAML internals.
    @original_yaml_words = Strategy.method(:yaml_words)
    @yaml_words_value = []
    yaml_words_proc = -> { @yaml_words_value }
    Strategy.define_singleton_method(:yaml_words) { yaml_words_proc.call }
  end

  teardown do
    Strategy.reset_yaml_cache!
    @gc_class.define_method(:get, @original_gc_get)
    Strategy.singleton_class.send(:remove_method, :yaml_words) rescue nil
    Strategy.define_singleton_method(:yaml_words, @original_yaml_words) if @original_yaml_words
  end

  def set_blocklist(value)
    @overrides["CONTENT_MODERATION_BLOCKLIST"] = value
  end

  def set_yaml_words(words)
    @yaml_words_value = words
  end

  test "returns compliant when the blocklist is empty" do
    set_blocklist("")

    result = Strategy.new(text: "some text").perform

    assert_equal "compliant", result.status
    assert_equal [], result.reasoning
  end

  test "flags content containing blocked words" do
    set_blocklist("blocked, forbidden")

    result = Strategy.new(text: "This blocked phrase should match").perform

    assert_equal "flagged", result.status
    assert_equal ["Matched blocked word: blocked"], result.reasoning
  end

  test "matches blocked words case insensitively" do
    set_blocklist("SeCrEt")

    result = Strategy.new(text: "a SECRET appears here").perform

    assert_equal "flagged", result.status
    assert_equal ["Matched blocked word: secret"], result.reasoning
  end

  test "uses word boundaries when matching" do
    set_blocklist("art")

    result = Strategy.new(text: "partial article only").perform

    assert_equal "compliant", result.status
    assert_equal [], result.reasoning
  end

  test "reads words from the YAML source when present" do
    set_yaml_words(["yamlword"])
    set_blocklist("")

    result = Strategy.new(text: "this contains yamlword in it").perform

    assert_equal "flagged", result.status
    assert_equal ["Matched blocked word: yamlword"], result.reasoning
  end

  test "caches the YAML contents across calls" do
    # Validate that the strategy doesn't re-call yaml_words on every instance
    # in a way that bypasses the cache: count invocations.
    call_count = 0
    Strategy.singleton_class.send(:remove_method, :yaml_words) rescue nil
    Strategy.define_singleton_method(:yaml_words) do
      @yaml_words ||= begin
        call_count += 1
        ["word"]
      end
    end
    set_blocklist("")

    3.times { Strategy.new(text: "word").perform }

    assert_equal 1, call_count
  end

  test "unions YAML and GlobalConfig entries and deduplicates" do
    set_yaml_words(["yamlword", "shared"])
    set_blocklist("envword, Shared")

    result = Strategy.new(text: "mentions yamlword and envword and shared once").perform

    assert_equal "flagged", result.status
    assert_equal(
      ["Matched blocked word: yamlword", "Matched blocked word: shared", "Matched blocked word: envword"].sort,
      result.reasoning.sort
    )
  end
end
