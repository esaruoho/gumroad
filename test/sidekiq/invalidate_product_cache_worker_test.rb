# frozen_string_literal: true

require "test_helper"

class InvalidateProductCacheWorkerTest < ActiveSupport::TestCase
  test "expires the product cache" do
    product = links(:named_seller_product)
    called = false
    mod = Module.new
    mod.send(:define_method, :invalidate_cache) { called = true }
    Link.prepend(mod)

    InvalidateProductCacheWorker.new.perform(product.id)

    assert called, "expected Link#invalidate_cache to be called"
  ensure
    mod.module_eval { remove_method(:invalidate_cache) } if mod
  end
end
