# frozen_string_literal: true

require "test_helper"

class Exports::TaxSummary::PayableTest < ActiveSupport::TestCase
  setup do
    @year = 2019
    @user = users(:tax_summary_payable_seller)
    @compliance_info = UserComplianceInfo.find(ActiveRecord::FixtureSet.identify(:tax_summary_payable_compliance_info))
    @merchant_account = merchant_accounts(:tax_summary_payable_stripe_account)
  end

  test "#perform generates total transactions count" do
    row = payable_row

    assert_equal "12", row[24]
  end

  test "#perform generates total transactions amount" do
    row = payable_row

    assert_equal (tax_summary_purchases.sum(&:total_transaction_cents) / 100.0).to_s, row[21]
  end

  test "#perform creates monthly breakdown with transaction amount" do
    row = payable_row

    assert_equal tax_summary_purchases.map { (_1.total_transaction_cents / 100.0).to_s }.sort, row[26..37].sort
  end

  test "#perform adds compliance and other user related fields" do
    row = payable_row

    assert_equal @user.external_id, row[1]
    assert_equal @merchant_account.charge_processor_merchant_id, row[2]
    assert_equal [@compliance_info.first_and_last_name, @compliance_info.first_name, @compliance_info.last_name, @compliance_info.legal_entity_name], row[3..6]
    assert_equal @user.email, row[7]
    assert_equal [
      @compliance_info.legal_entity_street_address,
      nil,
      @compliance_info.legal_entity_city,
      @compliance_info.legal_entity_state_code,
      @compliance_info.legal_entity_zip_code,
      @compliance_info.legal_entity_country_code,
    ], row[8..13]
    assert_equal @compliance_info.legal_entity_payable_business_type, row[14]
    assert_equal "EPF Other", row[17]
    assert_equal "Third Party Network", row[18]
    assert_equal "Gumroad", row[19]
    assert_equal "(650) 204-3486", row[20]
  end

  test "#perform adds tax id if user is an individual" do
    row = payable_row

    assert_equal @compliance_info.individual_tax_id.decrypt(GlobalConfig.get("STRONGBOX_GENERAL_PASSWORD")), row[15]
  end

  test "#perform adds individual tax id and business tax id if user is a business" do
    business_user = users(:tax_summary_payable_business_seller)
    compliance_info = UserComplianceInfo.find(ActiveRecord::FixtureSet.identify(:tax_summary_payable_business_compliance_info))
    row = CSV.parse(Exports::TaxSummary::Payable.new(user: business_user, year: @year).perform)[1]

    assert_equal compliance_info.individual_tax_id.decrypt(GlobalConfig.get("STRONGBOX_GENERAL_PASSWORD")), row[15]
    assert_equal compliance_info.business_tax_id.decrypt(GlobalConfig.get("STRONGBOX_GENERAL_PASSWORD")), row[16]
  end

  test "#perform returns no data if no payments exist" do
    assert_nil Exports::TaxSummary::Payable.new(user: users(:basic_user), year: @year).perform
  end

  private
    def payable_row
      CSV.parse(Exports::TaxSummary::Payable.new(user: @user, year: @year).perform)[1]
    end

    def tax_summary_purchases
      @user.sales.where(created_at: Date.new(@year).all_year).to_a
    end
end
