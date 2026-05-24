# frozen_string_literal: true

require "test_helper"

class SendToElasticsearchWorkerTest < ActiveSupport::TestCase
  test "delegates to ProductIndexingService.perform with index action" do
    product = links(:named_seller_product)
    captured = nil
    ProductIndexingService.stub(:perform, ->(**kwargs) { captured = kwargs }) do
      SendToElasticsearchWorker.new.perform(product.id, "index")
    end
    assert_equal product.id, captured[:product].id
    assert_equal "index", captured[:action]
    assert_equal [], captured[:attributes_to_update]
  end

  test "delegates to ProductIndexingService.perform with update action and attributes" do
    product = links(:named_seller_product)
    captured = nil
    ProductIndexingService.stub(:perform, ->(**kwargs) { captured = kwargs }) do
      SendToElasticsearchWorker.new.perform(product.id, "update", %w[name tags])
    end
    assert_equal "update", captured[:action]
    assert_equal %w[name tags], captured[:attributes_to_update]
  end

  test "returns early when product is not found" do
    called = false
    ProductIndexingService.stub(:perform, ->(**_kwargs) { called = true }) do
      SendToElasticsearchWorker.new.perform(0, "index")
    end
    refute called
  end
end
