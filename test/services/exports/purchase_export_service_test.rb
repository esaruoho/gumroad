# frozen_string_literal: true

require "test_helper"
require "csv"

class Exports::PurchaseExportServiceTest < ActiveSupport::TestCase
  test "compile writes purchase rows custom fields and totals" do
    tempfile = Exports::PurchaseExportService.compile(
      ["Question"],
      [
        [
          {
            "Purchase ID" => "purchase-1",
            "Buyer Name" => "Jane",
            "Sale Price ($)" => 10.25,
            "Fees ($)" => 1.25,
          },
          { "Question" => "Blue" }
        ],
        [
          {
            "Purchase ID" => "purchase-2",
            "Buyer Name" => "John",
            "Sale Price ($)" => 2.25,
            "Fees ($)" => 0.25,
          },
          { "Question" => "Green" }
        ],
      ]
    )

    rows = CSV.read(tempfile.path, headers: true)
    assert_equal "purchase-1", rows[0]["Purchase ID"]
    assert_equal "Blue", rows[0]["Question"]
    assert_equal "purchase-2", rows[1]["Purchase ID"]
    assert_equal "Green", rows[1]["Question"]
    assert_equal Exports::PurchaseExportService::TOTALS_COLUMN_NAME, rows[2]["Purchase ID"]
    assert_equal "12.5", rows[2]["Sale Price ($)"]
    assert_equal "1.5", rows[2]["Fees ($)"]
  ensure
    tempfile&.close!
  end

  test "compile writes duplicate custom field values to the last matching column" do
    tempfile = Exports::PurchaseExportService.compile(
      ["Purchase ID"],
      [
        [
          { "Purchase ID" => "purchase-1" },
          { "Purchase ID" => "custom-value" }
        ],
      ]
    )

    row = CSV.read(tempfile.path).second
    assert_equal "purchase-1", row[0]
    assert_equal "custom-value", row.last
  ensure
    tempfile&.close!
  end

  test "export performs synchronously when result count is below threshold" do
    seller = users(:basic_user)
    recipient = users(:purchaser)
    purchase = purchases(:auto_invoice_enabled_purchase)
    captured_options = nil
    search_service = fake_search_service(query: { bool: { filter: [] } }, result_ids: [purchase.id])
    exported_records = nil
    service = Minitest::Mock.new
    service.expect(:perform, :csv_file)

    PurchaseSearchService.stub(:new, ->(*args, **options) {
      options = args.first if options.empty?
      captured_options = options
      search_service
    }) do
      EsClient.stub(:count, ->(index:, body:) {
        assert_equal Purchase.index_name, index
        assert_equal({ query: search_service.query }, body)
        { "count" => 1 }
      }) do
        Exports::PurchaseExportService.stub(:new, ->(records) {
          exported_records = records
          service
        }) do
          assert_equal :csv_file, Exports::PurchaseExportService.export(seller:, recipient:)
        end
      end
    end
    service.verify

    assert_equal seller, captured_options[:seller]
    assert_equal Purchase::NON_GIFT_SUCCESS_STATES, captured_options[:state]
    assert_equal true, captured_options[:exclude_not_charged_non_free_trial_purchases]
    assert_equal true, captured_options[:exclude_bundle_product_purchases]
    assert_equal Exports::PurchaseExportService::SYNCHRONOUS_EXPORT_THRESHOLD, captured_options[:size]
    assert_equal [purchase.id], exported_records.pluck(:id)
  end

  test "export enqueues async chunk processing when count exceeds the threshold" do
    seller = users(:basic_user)
    recipient = users(:purchaser)
    search_service = fake_search_service(query: { bool: { filter: [{ term: { seller_id: seller.id } }] } }, result_ids: [])
    export = Struct.new(:id).new(123)
    enqueued_export_ids = []

    PurchaseSearchService.stub(:new, ->(*_args, **_options) { search_service }) do
      EsClient.stub(:count, { "count" => Exports::PurchaseExportService::SYNCHRONOUS_EXPORT_THRESHOLD + 1 }) do
        SalesExport.stub(:create!, ->(**kwargs) {
          assert_equal({ recipient:, query: search_service.query.deep_stringify_keys }, kwargs)
          export
        }) do
          Exports::Sales::CreateAndEnqueueChunksWorker.stub(:perform_async, ->(export_id) { enqueued_export_ids << export_id }) do
            assert_equal false, Exports::PurchaseExportService.export(seller:, recipient:)
          end
        end

        assert_equal [export.id], enqueued_export_ids
      end
    end
  end

  test "export enqueues async chunk processing when forced" do
    seller = users(:basic_user)
    recipient = users(:purchaser)
    search_service = fake_search_service(query: { bool: { filter: [] } }, result_ids: [])
    export = Struct.new(:id).new(456)
    enqueued_export_ids = []

    PurchaseSearchService.stub(:new, ->(*_args, **_options) { search_service }) do
      EsClient.stub(:count, { "count" => 1 }) do
        SalesExport.stub(:create!, ->(**kwargs) {
          assert_equal({ recipient:, query: search_service.query.deep_stringify_keys }, kwargs)
          export
        }) do
          Exports::Sales::CreateAndEnqueueChunksWorker.stub(:perform_async, ->(export_id) { enqueued_export_ids << export_id }) do
            assert_equal false, Exports::PurchaseExportService.export(seller:, recipient:, force_async: true)
          end
        end

        assert_equal [export.id], enqueued_export_ids
      end
    end
  end

  test "export resolves product variant and date filters before searching" do
    seller = users(:basic_user)
    recipient = users(:purchaser)
    product = links(:basic_user_product)
    variant = base_variants(:variant_price_test_standalone_variant)
    product_external_id = "product-ext"
    variant_external_id = "variant-ext"
    captured_options = nil
    search_service = fake_search_service(query: { bool: { filter: [] } }, result_ids: [])
    product_scope = Struct.new(:ids).new([product.id])
    variant_scope = Struct.new(:ids).new([variant.id])

    Link.stub(:by_external_ids, ->(external_ids) {
      assert_equal [product_external_id], external_ids
      product_scope
    }) do
      BaseVariant.stub(:by_external_ids, ->(external_ids) {
        assert_equal [variant_external_id], external_ids
        variant_scope
      }) do
        PurchaseSearchService.stub(:new, ->(*args, **options) {
          options = args.first if options.empty?
          captured_options = options
          search_service
        }) do
          EsClient.stub(:count, { "count" => Exports::PurchaseExportService::SYNCHRONOUS_EXPORT_THRESHOLD + 1 }) do
            SalesExport.stub(:create!, Struct.new(:id).new(789)) do
              Exports::Sales::CreateAndEnqueueChunksWorker.stub(:perform_async, nil) do

                Exports::PurchaseExportService.export(
                  seller:,
                  recipient:,
                  filters: {
                    product_ids: [product_external_id],
                    variant_ids: [variant_external_id],
                    start_time: "2026-05-01",
                    end_time: "2026-05-24",
                  }
                )
              end
            end
          end
        end
      end
    end

    assert_equal({ products: [product.id], variants: [variant.id] }, captured_options[:any_products_or_variants])
    assert_equal Date.parse("2026-05-01").in_time_zone("UTC").beginning_of_day, captured_options[:created_on_or_after]
    assert_equal Date.parse("2026-05-24").in_time_zone("UTC").end_of_day, captured_options[:created_before]
  end

  private
    def fake_search_service(query:, result_ids:)
      result = Struct.new(:id)
      results = result_ids.map { result.new(_1) }
      process_result = Struct.new(:results).new(results)
      Struct.new(:query, :process).new(query, process_result)
    end
end
