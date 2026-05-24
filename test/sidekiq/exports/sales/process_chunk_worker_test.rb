# frozen_string_literal: true

require "test_helper"

class Exports::Sales::ProcessChunkWorkerTest < ActiveSupport::TestCase
  setup do
    @user = users(:named_seller)
    @export = SalesExport.new(recipient: @user, query: { seller_id: @user.id })
    @export.save!(validate: false)
    @chunk = SalesExportChunk.new(export: @export, purchase_ids: [], revision: 0, processed: false)
    @chunk.save!(validate: false)
  end

  test "processes chunk and enqueues compile when no other chunks remain" do
    service_double = Object.new
    service_double.define_singleton_method(:custom_fields) { ["field_a"] }
    service_double.define_singleton_method(:purchases_data) { [{ id: 1 }] }
    Exports::PurchaseExportService.stub(:new, ->(_purchases) { service_double }) do
      compile_enqueued = []
      Exports::Sales::CompileChunksWorker.stub(:perform_async, ->(eid) { compile_enqueued << eid }) do
        Exports::Sales::ProcessChunkWorker.new.perform(@chunk.id)
      end
      assert_equal [@export.id], compile_enqueued
    end
    @chunk.reload
    assert @chunk.processed
    assert_equal ["field_a"], @chunk.custom_fields
  end

  test "does not enqueue compile when other chunks remain unprocessed" do
    other = SalesExportChunk.new(export: @export, purchase_ids: [], revision: 0, processed: false)
    other.save!(validate: false)
    service_double = Object.new
    service_double.define_singleton_method(:custom_fields) { [] }
    service_double.define_singleton_method(:purchases_data) { [] }
    Exports::PurchaseExportService.stub(:new, ->(_p) { service_double }) do
      compile_enqueued = []
      Exports::Sales::CompileChunksWorker.stub(:perform_async, ->(eid) { compile_enqueued << eid }) do
        Exports::Sales::ProcessChunkWorker.new.perform(@chunk.id)
      end
      assert_empty compile_enqueued
    end
  end
end
