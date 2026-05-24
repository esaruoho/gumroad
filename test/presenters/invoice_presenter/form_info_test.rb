# frozen_string_literal: true

require "test_helper"

class InvoicePresenter::FormInfoTest < ActiveSupport::TestCase
  setup do
    @purchase = purchases(:invoice_seller_purchase)
    @sales_tax_info = purchase_sales_tax_infos(:invoice_seller_purchase_sales_tax_info)
  end

  def presenter(chargeable = @purchase, buyer: nil)
    InvoicePresenter::FormInfo.new(chargeable, buyer:)
  end

  test "#heading returns Generate invoice when not direct to Australian customer" do
    assert_equal "Generate invoice", presenter.heading
  end

  test "#heading returns Generate receipt when direct to Australian customer" do
    @purchase.link.update_column(:flags, @purchase.link.flags | 128) # is_physical
    @purchase.update_columns(country: "Australia")
    assert_equal "Generate receipt", presenter.heading
  end

  test "#display_vat_id? returns false without gumroad tax" do
    @purchase.update_columns(gumroad_tax_cents: 0)
    refute presenter.display_vat_id?
  end

  test "#display_vat_id? returns false when business_vat_id is provided" do
    @sales_tax_info.update!(business_vat_id: "123")
    refute presenter.display_vat_id?
  end

  test "#display_vat_id? returns true when gumroad tax present and no business_vat_id" do
    assert presenter.display_vat_id?
  end

  test "#vat_id_label returns ABN when country is Australia" do
    @sales_tax_info.update!(country_code: Compliance::Countries::AUS.alpha2)
    assert_equal "Business ABN ID (Optional)", presenter.vat_id_label
  end

  test "#vat_id_label returns GST when country is Singapore" do
    @sales_tax_info.update!(country_code: Compliance::Countries::SGP.alpha2)
    assert_equal "Business GST ID (Optional)", presenter.vat_id_label
  end

  test "#vat_id_label returns MVA when country is Norway" do
    @sales_tax_info.update!(country_code: Compliance::Countries::NOR.alpha2)
    assert_equal "Norway MVA ID (Optional)", presenter.vat_id_label
  end

  test "#vat_id_label returns QST when state is Quebec, Canada" do
    @sales_tax_info.update!(country_code: Compliance::Countries::CAN.alpha2, state_code: "QC")
    assert_equal "Business QST ID (Optional)", presenter.vat_id_label
  end

  test "#vat_id_label returns VAT for other countries" do
    assert_equal "Business VAT ID (Optional)", presenter.vat_id_label
  end

  test "#business_id_country_codes includes EU member states" do
    eu = %w[AT BE BG HR CY CZ DK EE FI FR DE GR HU IE IT LV LT LU MT NL PL PT RO SK SI ES SE]
    eu.each { |code| assert_includes presenter.business_id_country_codes, code }
  end

  test "#business_id_country_codes includes the United Kingdom" do
    assert_includes presenter.business_id_country_codes, "GB"
  end

  test "#business_id_country_codes does not include the United States" do
    refute_includes presenter.business_id_country_codes, "US"
  end

  test "#business_id_labels maps EU member states to VAT ID" do
    labels = presenter.business_id_labels
    %w[DE FR IT ES NL BE IE].each { |code| assert_equal "VAT ID", labels[code] }
  end

  test "#business_id_labels maps non-EU jurisdictions to their local label" do
    labels = presenter.business_id_labels
    assert_equal "GB VAT", labels["GB"]
    assert_equal "ABN", labels["AU"]
    assert_equal "CNPJ", labels["BR"]
    assert_equal "RFC", labels["MX"]
    assert_equal "Consumption tax", labels["JP"]
    assert_equal "GST/HST", labels["CA"]
  end

  test "#business_id_labels does not include countries outside the business-ID scope" do
    refute presenter.business_id_labels.key?("US")
  end

  test "#data returns form data with address fields from purchase" do
    @purchase.update_columns(
      full_name: "Customer Name",
      street_address: "1234 Main St",
      city: "City",
      state: "State",
      zip_code: "12345",
      country: "United States"
    )

    form_data = presenter.data
    assert_equal "Customer Name", form_data[:address_fields][:full_name]
    assert_equal "1234 Main St", form_data[:address_fields][:street_address]
    assert_equal "City", form_data[:address_fields][:city]
    assert_equal "State", form_data[:address_fields][:state]
    assert_equal "12345", form_data[:address_fields][:zip_code]
    assert_equal "US", form_data[:address_fields][:country_code]
    assert_equal @purchase.email, form_data[:email]
    assert_equal "", form_data[:business_name]
    assert_equal "", form_data[:vat_id]
    assert_equal "", form_data[:additional_notes]
  end
end
