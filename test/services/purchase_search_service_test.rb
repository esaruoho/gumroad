# frozen_string_literal: true

require "test_helper"

class PurchaseSearchServiceTest < ActiveSupport::TestCase
  test "DEFAULT_OPTIONS includes expected filter keys with safe defaults" do
    defaults = PurchaseSearchService::DEFAULT_OPTIONS

    # core "filter by" options default to nil so an unfiltered call returns everything
    assert_nil defaults[:seller]
    assert_nil defaults[:purchaser]
    assert_nil defaults[:product]
    assert_nil defaults[:variant]

    # boolean exclusion flags default to false
    assert_equal false, defaults[:exclude_refunded]
    assert_equal false, defaults[:exclude_unreversed_chargedback]
    assert_equal false, defaults[:exclude_giftees]
    assert_equal false, defaults[:exclude_non_original_subscription_purchases]
  end

  test ".search delegates to new(opts).process" do
    captured = {}
    fake_instance = Object.new
    fake_instance.define_singleton_method(:process) { :result_sentinel }

    original_new = PurchaseSearchService.method(:new)
    PurchaseSearchService.define_singleton_method(:new) do |opts|
      captured[:opts] = opts
      fake_instance
    end
    begin
      result = PurchaseSearchService.search(seller: :sentinel, exclude_refunded: true)
    ensure
      PurchaseSearchService.define_singleton_method(:new, original_new)
    end

    assert_equal({ seller: :sentinel, exclude_refunded: true }, captured[:opts])
    assert_equal :result_sentinel, result
  end

  # TODO: full search behaviour (148 FactoryBot refs in the original spec) requires
  # the Elasticsearch test harness — purchases get indexed and asserted against
  # native ES filter/sort/aggregation responses. Out of scope for the fixture-only
  # Minitest lane. Original: spec/services/purchase_search_service_spec.rb
end
