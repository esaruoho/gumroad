# frozen_string_literal: true

require "test_helper"

# ElasticsearchSetup is defined in spec/support/elasticsearch.rb (a Ruby file
# whose top-level only sets a logger on EsClient and reopens an Elasticsearch
# module to add *_and_wait_for_refresh aliases). We load it directly so the
# class is available to the test without dragging in any RSpec dependency.
require Rails.root.join("spec", "support", "elasticsearch")

class ElasticsearchSetupTest < ActiveSupport::TestCase
  # Build a fake model that records calls on `__elasticsearch__`.
  def build_model(elasticsearch_proxy, index_name: "link-test")
    Class.new do
      define_singleton_method(:index_name) { index_name }
      define_singleton_method(:__elasticsearch__) { elasticsearch_proxy }
    end
  end

  # Fake proxy that captures create_index! / delete_index! call counts and
  # lets the test queue up return values or exceptions for create_index!.
  class FakeEsProxy
    attr_reader :delete_calls, :create_calls

    def initialize(create_results)
      @create_results = create_results.dup
      @delete_calls = []
      @create_calls = []
    end

    def delete_index!(force: false)
      @delete_calls << { force: force }
      true
    end

    def create_index!
      @create_calls << :called
      result = @create_results.shift
      raise result if result.is_a?(Exception)
      result
    end
  end

  # Swap EsClient.indices for the duration of the block.
  def with_indices_proxy(indices_proxy)
    original = EsClient
    fake = Object.new
    fake.define_singleton_method(:indices) { indices_proxy }
    fake.define_singleton_method(:transport) { original.transport }
    with_const(:EsClient, fake) { yield }
  end

  test "treats index already exists errors as success when the index is present" do
    bad_request = Elasticsearch::Transport::Transport::Errors::BadRequest.new("resource_already_exists_exception")
    elasticsearch_proxy = FakeEsProxy.new([bad_request])
    model = build_model(elasticsearch_proxy)

    indices_proxy = Object.new
    exists_calls = []
    indices_proxy.define_singleton_method(:exists?) do |index:|
      exists_calls << index
      true
    end

    with_indices_proxy(indices_proxy) do
      ElasticsearchSetup.recreate_index(model)
    end

    assert_equal [{ force: true }], elasticsearch_proxy.delete_calls
    assert_equal ["link-test"], exists_calls
  end

  test "retries until the index exists" do
    # create_index! returns nil (falsey) twice; first call -> retry path,
    # second call -> index_exists? then returns true.
    elasticsearch_proxy = FakeEsProxy.new([nil, nil])
    model = build_model(elasticsearch_proxy)

    indices_proxy = Object.new
    exists_results = [false, true]
    indices_proxy.define_singleton_method(:exists?) { |index:| exists_results.shift }

    sleep_calls = []
    ElasticsearchSetup.define_singleton_method(:sleep) { |n| sleep_calls << n }

    begin
      with_indices_proxy(indices_proxy) { ElasticsearchSetup.recreate_index(model) }
    ensure
      ElasticsearchSetup.singleton_class.send(:remove_method, :sleep)
    end

    # Initial delete + one retry-delete = 2 deletes
    assert_equal 2, elasticsearch_proxy.delete_calls.size
    assert_equal [0.1], sleep_calls
  end
end
