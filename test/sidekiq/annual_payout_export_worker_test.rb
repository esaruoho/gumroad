# frozen_string_literal: true

require "test_helper"

class AnnualPayoutExportWorkerTest < ActiveSupport::TestCase
  setup do
    @user = users(:named_seller)
  end

  test "no-op when payout_data has no csv_file" do
    Exports::Payouts::Annual.stub(:new, ->(**_kw) {
      svc = Object.new
      svc.define_singleton_method(:perform) { { total_amount: 0, csv_file: nil } }
      svc
    }) do
      assert_nothing_raised { AnnualPayoutExportWorker.new.perform(@user.id, 2023) }
    end
  end

  test "no-op when payout_data is nil" do
    Exports::Payouts::Annual.stub(:new, ->(**_kw) {
      svc = Object.new
      svc.define_singleton_method(:perform) { nil }
      svc
    }) do
      assert_nothing_raised { AnnualPayoutExportWorker.new.perform(@user.id, 2023) }
    end
  end

  test "sends email when send_email is true and payout data has positive total" do
    csv = Tempfile.new("payout")
    csv.write("hello")
    csv.rewind

    delivered = []
    mail = Object.new
    mail.define_singleton_method(:deliver_now) { delivered << :now }
    ContactingCreatorMailer.stub(:annual_payout_summary, ->(uid, yr, amt) {
      assert_equal @user.id, uid
      assert_equal 2023, yr
      assert_equal 5000, amt
      mail
    }) do
      User.define_method(:financial_annual_report_url_for) { |**_kw| "http://existing.example/foo.csv" }
      begin
        Exports::Payouts::Annual.stub(:new, ->(**_kw) {
          svc = Object.new
          svc.define_singleton_method(:perform) { { csv_file: csv, total_amount: 5000 } }
          svc
        }) do
          AnnualPayoutExportWorker.new.perform(@user.id, 2023, true)
        end
      ensure
        User.remove_method(:financial_annual_report_url_for) if User.method_defined?(:financial_annual_report_url_for)
      end
    end
    assert_equal [:now], delivered
  end
end
