# frozen_string_literal: true

require "test_helper"

class DuplicateProductWorkerTest < ActiveSupport::TestCase
  setup do
    @product = links(:named_seller_product)
  end

  test "duplicates product successfully" do
    product = @product
    name = product.name
    fake_dup = ->(_pid) do
      Object.new.tap do |o|
        o.define_singleton_method(:duplicate) do
          copy = product.dup
          copy.name = "#{name} (copy)"
          copy.unique_permalink = SecureRandom.hex(6)
          copy.save!(validate: false)
          copy
        end
      end
    end
    ProductDuplicatorService.stub(:new, fake_dup) do
      assert_difference -> { Link.count }, 1 do
        DuplicateProductWorker.new.perform(@product.id)
      end
    end
    assert Link.exists?(name: "#{@product.name} (copy)")
  end

  test "sets product is_duplicating to false" do
    product = @product
    @product.is_duplicating = true
    @product.save!(validate: false)
    fake_dup = ->(_pid) do
      Object.new.tap do |o|
        o.define_singleton_method(:duplicate) do
          copy = product.dup
          copy.unique_permalink = SecureRandom.hex(6)
          copy.save!(validate: false)
          copy
        end
      end
    end
    ProductDuplicatorService.stub(:new, fake_dup) do
      DuplicateProductWorker.new.perform(@product.id)
    end
    assert_equal false, @product.reload.is_duplicating
  end

  test "sets product is_duplicating to false on failure" do
    @product.is_duplicating = true
    @product.save!(validate: false)
    failing = ->(_pid) { Object.new.tap { |o| o.define_singleton_method(:duplicate) { raise StandardError } } }
    ErrorNotifier.stub(:notify, ->(_e) {}) do
      ProductDuplicatorService.stub(:new, failing) do
        assert_no_difference -> { Link.count } do
          DuplicateProductWorker.new.perform(@product.id)
        end
      end
    end
    assert_equal false, @product.reload.is_duplicating
  end

  test "logs and notifies error tracker on failure" do
    error = StandardError.new("Something broke")
    failing = ->(_pid) { Object.new.tap { |o| o.define_singleton_method(:duplicate) { raise error } } }
    notify_calls = []
    ErrorNotifier.stub(:notify, ->(e) { notify_calls << e }) do
      ProductDuplicatorService.stub(:new, failing) do
        DuplicateProductWorker.new.perform(@product.id)
      end
    end
    assert_equal [error], notify_calls
  end
end
