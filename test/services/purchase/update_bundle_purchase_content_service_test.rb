# frozen_string_literal: true

require "test_helper"

class Purchase::UpdateBundlePurchaseContentServiceTest < ActiveSupport::TestCase
  test "TODO: migrate spec/services/purchase/update_bundle_purchase_content_service_spec.rb" do
    skip "Requires create_artifacts_and_send_receipt! (PDF receipt generation + sidekiq fan-out + url_redirect creation) plus bundle/bundle_product/product_with_digital_versions fixtures with variants. Net fixture surface: ~10 new rows across links, prices, bundle_products, variants, variant_categories, url_redirects."
  end
end
