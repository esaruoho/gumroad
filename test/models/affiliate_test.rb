# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Affiliate spec (266 LOC, 54 create() refs) covers
# the Affiliate STI hierarchy (DirectAffiliate / GlobalAffiliate / Collaborator
# + :with_pending_invitation trait) and Affiliate.for_product / discover scopes,
# which transitively call `product.recommendable?` — that routes through
# `RecommendableProducts` + `PurchaseSearchService` (Elasticsearch). Plus the
# affiliate_user / seller balance + commission percentage matrix needs
# fixtures for product/seller/affiliate triples. Out of scope for mechanical
# model backfill.
#
# Original spec: spec/models/affiliate_spec.rb
class AffiliateTest < ActiveSupport::TestCase
  test "TODO: migrate — STI scopes + recommendable? (ES) + commission matrix" do
    skip "54 create() refs across DirectAffiliate/GlobalAffiliate/Collaborator STI scopes, product.recommendable? → ES path, affiliate/seller/product commission triples. Out of scope for mechanical model backfill."
  end
end
