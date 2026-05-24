# frozen_string_literal: true

require "test_helper"

class Exports::AffiliateExportServiceTest < ActiveSupport::TestCase
  setup do
    @seller = users(:named_seller)
    # Wipe pre-existing affiliate rows so we control what the service sees.
    Affiliate.where(seller_id: @seller.id).update_all(deleted_at: Time.current)
  end

  test "filename includes seller username" do
    service = Exports::AffiliateExportService.new(@seller)

    assert_match(/Affiliates-#{Regexp.escape(@seller.username)}_.*\.csv/, service.filename)
  end

  test "#perform writes header row and totals row even with no affiliates" do
    service = Exports::AffiliateExportService.new(@seller).perform

    rows = CSV.parse(service.tempfile.read)
    assert_equal Exports::AffiliateExportService::AFFILIATE_FIELDS, rows.first
    assert_equal "Totals", rows.last.first
  end

  test "#perform emits a data row per alive direct_affiliate" do
    affiliate_user = users(:another_seller)
    affiliate = DirectAffiliate.create!(
      seller: @seller,
      affiliate_user: affiliate_user,
      affiliate_basis_points: 1000
    )

    service = Exports::AffiliateExportService.new(@seller).perform
    rows = CSV.parse(service.tempfile.read)

    assert_equal 3, rows.size # header + 1 data row + totals
    headers = rows.first
    data_row = rows.second
    totals_row = rows.last

    assert_equal affiliate.external_id_numeric.to_s, data_row[headers.index("Affiliate ID")]
    assert_equal affiliate_user.email, data_row[headers.index("Email")]
    assert_equal "10 %", data_row[headers.index("Fee")]
    assert_equal "Totals", totals_row.first
  end

  test "#perform omits deleted affiliates" do
    affiliate_user = users(:another_seller)
    DirectAffiliate.create!(seller: @seller, affiliate_user: affiliate_user, affiliate_basis_points: 1000).mark_deleted!

    service = Exports::AffiliateExportService.new(@seller).perform
    rows = CSV.parse(service.tempfile.read)

    assert_equal 2, rows.size # header + totals only
  end

  test ".export returns performed service synchronously when below threshold" do
    DirectAffiliate.create!(seller: @seller, affiliate_user: users(:another_seller), affiliate_basis_points: 500)

    stub_constant(Exports::AffiliateExportService, :SYNCHRONOUS_EXPORT_THRESHOLD, 5) do
      result = Exports::AffiliateExportService.export(seller: @seller)
      assert_kind_of Exports::AffiliateExportService, result
      assert_kind_of String, result.filename
      assert_kind_of Tempfile, result.tempfile
    end
  end

  test ".export enqueues background worker when above threshold" do
    DirectAffiliate.create!(seller: @seller, affiliate_user: users(:another_seller), affiliate_basis_points: 500)
    recipient = users(:basic_user)

    Exports::AffiliateExportWorker.jobs.clear
    stub_constant(Exports::AffiliateExportService, :SYNCHRONOUS_EXPORT_THRESHOLD, 0) do
      result = Exports::AffiliateExportService.export(seller: @seller, recipient: recipient)
      assert_equal false, result
    end
    assert_equal 1, Exports::AffiliateExportWorker.jobs.size
    assert_equal [@seller.id, recipient.id], Exports::AffiliateExportWorker.jobs.last["args"]
  end

  private
    def stub_constant(mod, name, value)
      original = mod.const_get(name)
      mod.send(:remove_const, name)
      mod.const_set(name, value)
      yield
    ensure
      mod.send(:remove_const, name)
      mod.const_set(name, original)
    end
end
