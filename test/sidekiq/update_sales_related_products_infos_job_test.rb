# frozen_string_literal: true

require "test_helper"

class UpdateSalesRelatedProductsInfosJobTest < ActiveSupport::TestCase
  test "returns early when feature flag is inactive" do
    Feature.stub(:inactive?, ->(name) { name == :update_sales_related_products_infos }) do
      called = false
      Purchase.stub(:find, ->(_id) { called = true; nil }) do
        UpdateSalesRelatedProductsInfosJob.new.perform(123)
      end
      refute called, "Purchase.find should not be called when feature is inactive"
    end
  end

  test "returns early when no related products are found for purchase email" do
    Feature.stub(:inactive?, ->(_n) { false }) do
      purchase = Purchase.new(email: "lonely-buyer-#{SecureRandom.hex(4)}@example.com",
                              link_id: 42)
      def purchase.id; 999; end
      Purchase.stub(:find, ->(_id) { purchase }) do
        called = false
        SalesRelatedProductsInfo.stub(:update_sales_counts, ->(**_kw) { called = true }) do
          UpdateSalesRelatedProductsInfosJob.new.perform(999)
        end
        refute called
      end
    end
  end
end
