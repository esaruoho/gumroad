# frozen_string_literal: true

require "test_helper"

class PostToPingEndpointsWorkerTest < ActiveSupport::TestCase
  setup do
    @product = links(:named_seller_product)
    @seller = @product.user
    @purchase = Purchase.new(seller: @seller, link: @product, email: "buyer@example.com",
                              price_cents: 100, total_transaction_cents: 100, fee_cents: 0,
                              purchase_state: "successful")
    @purchase.save!(validate: false)
    # Stick-to-primary touches AR connection; harmless in test but stub for safety.
    ActiveRecord::Base.connection.define_singleton_method(:stick_to_primary!) { nil }
    @enqueued = []
    PostToIndividualPingEndpointWorker.define_singleton_method(:perform_async) do |*args|
      PostToPingEndpointsWorkerTest.enqueued_calls << args
    end
    self.class.class_variable_set(:@@enq, @enqueued)
  end

  def self.enqueued_calls; class_variable_get(:@@enq); end

  teardown do
    PostToIndividualPingEndpointWorker.singleton_class.send(:remove_method, :perform_async)
    ActiveRecord::Base.connection.singleton_class.send(:remove_method, :stick_to_primary!) if ActiveRecord::Base.connection.singleton_class.method_defined?(:stick_to_primary!)
  end

  test "no-ops when seller has no ping endpoints" do
    @purchase.define_singleton_method(:payload_for_ping_notification) { |**_| { foo: "bar" } }
    Purchase.stub(:find, ->(_id) { @purchase }) do
      PostToPingEndpointsWorker.new.perform(@purchase.id, { "a" => 1 })
    end
    assert_empty @enqueued
  end

  test "enqueues a PostToIndividualPingEndpointWorker per valid post url" do
    @purchase.define_singleton_method(:payload_for_ping_notification) { |**_| { id: "abc" } }
    seller = @seller
    seller.define_singleton_method(:urls_for_ping_notification) do |_resource|
      [["https://hooks.example.com/sale", "application/json"], ["bad-url", "application/json"]]
    end
    ResourceSubscription.stub(:valid_post_url?, ->(url) { url.start_with?("https://") }) do
      Purchase.stub(:find, ->(_id) { @purchase }) do
        PostToPingEndpointsWorker.new.perform(@purchase.id, { "x" => 1 })
      end
    end
    assert_equal 1, @enqueued.size
    url, payload, content_type, user_id = @enqueued.first
    assert_equal "https://hooks.example.com/sale", url
    assert_equal({ "id" => "abc" }, payload)
    assert_equal "application/json", content_type
    assert_equal @seller.id, user_id
  end

  test "handles subscription branch and returns early when SUBSCRIPTION_ENDED but deactivated_at blank" do
    subscription = subscriptions(:named_seller_product_subscription)
    subscription.update_columns(deactivated_at: nil)
    Subscription.stub(:find, ->(_id) { subscription }) do
      PostToPingEndpointsWorker.new.perform(nil, {}, ResourceSubscription::SUBSCRIPTION_ENDED_RESOURCE_NAME, subscription.id)
    end
    assert_empty @enqueued
  end
end
