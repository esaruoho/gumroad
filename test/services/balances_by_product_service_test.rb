# frozen_string_literal: true

require "test_helper"

class BalancesByProductServiceTest < ActiveSupport::TestCase
  # Sharpened skip-stub.
  # Original spec at spec/services/balances_by_product_service_spec.rb relies on:
  #   - CollabProductHelper#setup_collab_purchases_for (RSpec support helper, factory-heavy)
  #   - index_model_records(Purchase) live Elasticsearch indexing helper
  #   - 50+ purchases × refund/chargeback state mutations through refund_purchase!
  #     (FlowOfFunds + balance recalculation chains)
  #   - service body builds ES aggregation buckets — no non-ES code path.
  # Out of scope for fixtures-only Minitest backfill.
  test "TODO: migrate spec/services/balances_by_product_service_spec.rb (ES indexing + collab purchase factory chain)" do
    skip "Awaiting ES-aggregation harness + collab purchase fixture chain"
  end
end
