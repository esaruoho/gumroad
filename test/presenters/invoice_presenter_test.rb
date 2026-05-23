# frozen_string_literal: true

require "test_helper"

class InvoicePresenterTest < ActiveSupport::TestCase
  setup do
    @seller = users(:invoice_seller)
    @purchase = purchases(:invoice_seller_purchase)
    @charge = charges(:invoice_seller_charge)
    @address_fields = {
      full_name: "Customer Name",
      street_address: "1234 Main St",
      city: "City",
      state: "State",
      zip_code: "12345",
      country: "United States"
    }
  end

  # Shared assertion helpers ---------------------------------------------------

  def assert_supplier_info(chargeable)
    presenter = InvoicePresenter.new(chargeable)
    info = presenter.supplier_info
    assert_kind_of InvoicePresenter::SupplierInfo, info
    assert_equal chargeable, info.send(:chargeable)
  end

  def assert_seller_info(chargeable)
    presenter = InvoicePresenter.new(chargeable)
    info = presenter.seller_info
    assert_kind_of InvoicePresenter::SellerInfo, info
    assert_equal chargeable, info.send(:chargeable)
  end

  def assert_order_info(chargeable)
    additional_notes = "Additional notes"
    business_vat_id = "VAT12345"
    presenter = InvoicePresenter.new(
      chargeable,
      address_fields: @address_fields,
      additional_notes: additional_notes,
      business_vat_id: business_vat_id
    )
    info = presenter.order_info
    assert_kind_of InvoicePresenter::OrderInfo, info
    assert_equal chargeable, info.send(:chargeable)
    assert_equal @address_fields, info.send(:address_fields)
    assert_equal additional_notes, info.send(:additional_notes)
    assert_equal business_vat_id, info.send(:business_vat_id)
  end

  def assert_invoice_generation_form_data_props(chargeable)
    presenter = InvoicePresenter.new(chargeable)
    props = presenter.invoice_generation_form_data_props

    assert_equal chargeable.external_id_for_invoice, props[:purchase_id]
    assert_kind_of Hash, props[:address_fields]
    assert_equal @purchase.email, props[:email]
    assert_equal "", props[:business_name]
    assert_equal "", props[:vat_id]
    assert_equal "", props[:additional_notes]
  end

  def assert_invoice_generation_form_metadata_props(chargeable)
    presenter = InvoicePresenter.new(chargeable)
    props = presenter.invoice_generation_form_metadata_props

    assert_kind_of String, props[:heading]
    assert_includes [true, false], props[:display_vat_id]
    assert_kind_of String, props[:vat_id_label]
    assert_kind_of Array, props[:business_id_country_codes]
    assert_kind_of Hash, props[:business_id_labels]
    assert_kind_of Hash, props[:supplier_info]
    assert_kind_of Hash, props[:seller_info]
    assert_kind_of Hash, props[:order_info]
    assert_kind_of Hash, props[:countries]

    assert_equal Compliance::Countries.for_select.to_h, props[:countries]
    %w[DE FR GB].each { |code| assert_includes props[:business_id_country_codes], code }
    assert_equal "VAT ID", props[:business_id_labels]["DE"]
    assert_equal "CNPJ", props[:business_id_labels]["BR"]
  end

  # For Purchase --------------------------------------------------------------

  test "Purchase: #supplier_info returns a SupplierInfo object" do
    assert_supplier_info(@purchase)
  end

  test "Purchase: #seller_info returns a SellerInfo object" do
    assert_seller_info(@purchase)
  end

  test "Purchase: #order_info returns an OrderInfo object" do
    assert_order_info(@purchase)
  end

  test "Purchase: #invoice_generation_form_data_props returns the form data" do
    assert_invoice_generation_form_data_props(@purchase)
  end

  test "Purchase: #invoice_generation_form_metadata_props returns the form metadata" do
    assert_invoice_generation_form_metadata_props(@purchase)
  end

  # For Charge ----------------------------------------------------------------

  test "Charge: #supplier_info returns a SupplierInfo object" do
    assert_supplier_info(@charge)
  end

  test "Charge: #seller_info returns a SellerInfo object" do
    assert_seller_info(@charge)
  end

  test "Charge: #order_info returns an OrderInfo object" do
    assert_order_info(@charge)
  end

  test "Charge: #invoice_generation_form_data_props returns the form data" do
    assert_invoice_generation_form_data_props(@charge)
  end

  test "Charge: #invoice_generation_form_metadata_props returns the form metadata" do
    assert_invoice_generation_form_metadata_props(@charge)
  end

  # NOTE: The original spec also covered a `:vcr` Canada sales tax breakdown
  # for both Purchase and Charge that drives in_progress purchases through
  # `process!` + `update_balance_and_mark_successful!`. That branch requires
  # the full chargeable/process pipeline and VCR cassettes, which are out of
  # scope for the fixtures-only Minitest migration. The structural assertions
  # above mirror the rest of the original spec.
end
