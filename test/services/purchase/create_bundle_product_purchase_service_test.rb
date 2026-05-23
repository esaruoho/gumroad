# frozen_string_literal: true

require "test_helper"

class Purchase::CreateBundleProductPurchaseServiceTest < ActiveSupport::TestCase
  test "TODO: migrate spec/services/purchase/create_bundle_product_purchase_service_spec.rb" do
    skip "9 FB: bundle (product is_bundle), product_with_digital_versions (variant_categories + variants), bundle_product, purchase, purchase_custom_field, gift, gift_sender_purchase, gift_receiver_purchase. Skip-batch per directive (>10 net-new fixture rows + 2 gift purchases with cross-FK chain)."
  end
end
