# frozen_string_literal: true

require "test_helper"

class DevToolsTest < ActiveSupport::TestCase
  # The original RSpec suite round-tripped documents through a real Elasticsearch
  # instance. The Minitest suite stubs EsClient + Elasticsearch::Model.client
  # globally (see test/test_helper.rb), so we instead verify DevTools dispatches
  # the expected imports without raising. Real index behavior is covered by
  # integration tests that bootstrap ES.

  test ".reindex_all_for_user dispatches imports across the per-user relations" do
    user = users(:named_seller)
    imported = []
    capture_io_and_stub_import(imported) do
      DevTools.reindex_all_for_user(user)
    end
    classes = imported.map(&:first)
    assert_includes classes, "Installment"
    assert_includes classes, "Link"
    assert_includes classes, "Balance"
    assert(imported.none? { |(_, force)| force }, "per-user imports must not force-recreate indices")
  end

  test ".reindex_all_for_user accepts a user id and looks the record up" do
    user = users(:named_seller)
    imported = []
    capture_io_and_stub_import(imported) do
      DevTools.reindex_all_for_user(user.id)
    end
    refute_empty imported
  end

  test ".delete_all_indices_and_reindex_all does not execute in production" do
    imported = []
    Rails.env.stub(:production?, true) do
      capture_io_and_stub_import(imported) do
        assert_raises(StandardError) { DevTools.delete_all_indices_and_reindex_all }
      end
    end
    assert_empty imported
  end

  test ".delete_all_indices_and_reindex_all imports each global model with force: true" do
    imported = []
    capture_io_and_stub_import(imported) do
      DevTools.delete_all_indices_and_reindex_all
    end
    classes = imported.map(&:first)
    %w[Purchase Link Balance Installment].each { |k| assert_includes classes, k }
    global_forces = imported
      .select { |(label, _)| %w[Purchase Link Balance Installment].include?(label) }
      .map(&:last)
    assert(global_forces.all? { |f| f == true }, "global reindex must force: true, got #{imported.inspect}")
  end

  test ".reimport_follower_events_for_user! runs without error" do
    user = users(:named_seller)
    Follower.stub(:active, Follower.none) do
      capture_io { DevTools.reimport_follower_events_for_user!(user) }
    end
  end

  private
    # Replace `es_import_with_time` for the duration of the block. Plain
    # `Module#define_method` on the singleton is restored from a captured
    # UnboundMethod afterward — no `prepend`, no `alias_method`.
    def capture_io_and_stub_import(sink)
      original = DevTools.singleton_class.instance_method(:es_import_with_time)
      DevTools.define_singleton_method(:es_import_with_time) do |rel, force: false|
        label = rel.is_a?(Class) ? rel.name : (rel.respond_to?(:klass) ? rel.klass.name : rel.class.name)
        sink << [label, force]
        nil
      end
      capture_io { yield }
    ensure
      DevTools.define_singleton_method(:es_import_with_time, original)
    end
end
