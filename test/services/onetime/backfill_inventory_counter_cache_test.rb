# frozen_string_literal: true

require "test_helper"

class Onetime::BackfillInventoryCounterCacheTest < ActiveSupport::TestCase
  test "BATCH_SIZE constant is configured" do
    assert_equal 1_000, Onetime::BackfillInventoryCounterCache::BATCH_SIZE
  end

  test ".process delegates to instance#process forwarding all keyword arguments" do
    captured = {}
    fake = Object.new
    fake.define_singleton_method(:process) do |**kwargs|
      captured.merge!(kwargs)
      :result_sentinel
    end

    original_new = Onetime::BackfillInventoryCounterCache.method(:new)
    Onetime::BackfillInventoryCounterCache.define_singleton_method(:new) { fake }
    begin
      result = Onetime::BackfillInventoryCounterCache.process(
        start_base_variant_id: 5,
        end_base_variant_id: 10,
        start_link_id: 1,
        end_link_id: 99,
        batch_size: 25
      )
    ensure
      Onetime::BackfillInventoryCounterCache.define_singleton_method(:new, original_new)
    end

    assert_equal :result_sentinel, result
    assert_equal 5, captured[:start_base_variant_id]
    assert_equal 10, captured[:end_base_variant_id]
    assert_equal 1, captured[:start_link_id]
    assert_equal 99, captured[:end_link_id]
    assert_equal 25, captured[:batch_size]
  end

  test ".process uses defaults when arguments are omitted" do
    captured = {}
    fake = Object.new
    fake.define_singleton_method(:process) { |**kwargs| captured.merge!(kwargs); :ok }

    original_new = Onetime::BackfillInventoryCounterCache.method(:new)
    Onetime::BackfillInventoryCounterCache.define_singleton_method(:new) { fake }
    begin
      Onetime::BackfillInventoryCounterCache.process
    ensure
      Onetime::BackfillInventoryCounterCache.define_singleton_method(:new, original_new)
    end

    assert_equal 0, captured[:start_base_variant_id]
    assert_nil captured[:end_base_variant_id]
    assert_equal 0, captured[:start_link_id]
    assert_nil captured[:end_link_id]
    assert_equal Onetime::BackfillInventoryCounterCache::BATCH_SIZE, captured[:batch_size]
  end

  # TODO: the full backfill loop (28 FactoryBot refs) iterates base_variants
  # and links in batches and asserts that quantity_left, inventory_counters,
  # and `last_seen_variant_attributes_blob` get refreshed. That requires
  # base_variants + skus + purchase event chains beyond the fixture surface
  # currently on this branch. Original:
  # spec/services/onetime/backfill_inventory_counter_cache_spec.rb
end
