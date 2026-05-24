# frozen_string_literal: true

require "test_helper"

class ReindexRecommendableProductsWorkerTest < ActiveSupport::TestCase
  # EsClient is globally stubbed in test_helper.rb to return an empty hits list.
  # That means the loop runs once with zero ids and exits.

  test "no-ops cleanly when ES returns no recommendable products" do
    pushed = []
    Sidekiq::Client.stub(:push_bulk, ->(args) { pushed << args }) do
      assert_nothing_raised do
        ReindexRecommendableProductsWorker.new.perform
      end
    end
    assert_empty pushed
  end

  test "schedules SendToElasticsearchWorker bulk pushes when ES returns hits with recent sales" do
    # Drive a single scroll response with two link ids.
    product = links(:named_seller_product)
    other_product = links(:basic_user_product)

    # Make sure there's a recent purchase for product so the filter survives.
    purchase = Purchase.new(seller: product.user, link: product, email: "buyer@example.com",
                            price_cents: 100, total_transaction_cents: 100, fee_cents: 0,
                            purchase_state: "successful", created_at: 1.day.ago)
    purchase.save!(validate: false)

    fake_es = Object.new
    fake_es.define_singleton_method(:search) do |**_kwargs|
      { "_scroll_id" => "abc",
        "hits" => { "hits" => [{ "_id" => product.id }, { "_id" => other_product.id }] } }
    end
    fake_es.define_singleton_method(:scroll) do |**_kwargs|
      { "_scroll_id" => "abc", "hits" => { "hits" => [] } }
    end
    fake_es.define_singleton_method(:clear_scroll) { |**_kwargs| nil }

    original = Object.const_get(:EsClient)
    Object.send(:remove_const, :EsClient)
    Object.const_set(:EsClient, fake_es)
    begin
      pushed = []
      Sidekiq::Client.stub(:push_bulk, ->(args) { pushed << args }) do
        ReindexRecommendableProductsWorker.new.perform
      end
      assert_equal 1, pushed.size
      assert_equal "SendToElasticsearchWorker", pushed.first["class"].name
      arg_ids = pushed.first["args"].map { _1.first }
      assert_includes arg_ids, product.id
      refute_includes arg_ids, other_product.id # no recent sales
    ensure
      Object.send(:remove_const, :EsClient)
      Object.const_set(:EsClient, original)
    end
  end
end
