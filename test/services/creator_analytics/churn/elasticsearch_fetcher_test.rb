require "test_helper"

# TODO: Migrate from RSpec. 9 FactoryBot refs. Original: spec/services/creator_analytics/churn/elasticsearch_fetcher_spec.rb
# Skip-batched during fixtures-only migration (mig-a) — service specs are Tier 3-4
# (subscription / purchase / Stripe / Elasticsearch / VCR chains) and require
# manual rewrite with fixtures post-deadline.
class CreatorAnalytics::Churn::ElasticsearchFetcherTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/services/creator_analytics/churn/elasticsearch_fetcher_spec.rb (9 FactoryBot refs)"
  end
end
