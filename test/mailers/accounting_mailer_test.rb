# frozen_string_literal: true

require "test_helper"

class AccountingMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options
    { host: DOMAIN, protocol: PROTOCOL }
  end

  # --- #vat_report -----------------------------------------------------------

  test "vat_report has the s3 link in the body" do
    mail = AccountingMailer.vat_report(3, 2015, "https://test_vat_link.at.s3")
    assert_includes mail.body.to_s, "VAT report Link: https://test_vat_link.at.s3"
  end

  test "vat_report indicates the quarter and year of reporting period in the subject" do
    mail = AccountingMailer.vat_report(3, 2015, "https://test_vat_link.at.s3")
    assert_equal "VAT report for Q3 2015", mail.subject
  end

  test "vat_report is to team" do
    mail = AccountingMailer.vat_report(3, 2015, "https://test_vat_link.at.s3")
    assert_equal [ApplicationMailer::PAYMENTS_EMAIL], mail.to
  end

  # --- #gst_report -----------------------------------------------------------

  test "gst_report contains the s3 link in the body" do
    mail = AccountingMailer.gst_report("AU", 3, 2015, "https://test_vat_link.at.s3")
    assert_includes mail.body.to_s, "GST report Link: https://test_vat_link.at.s3"
  end

  test "gst_report indicates the quarter and year of reporting period in the subject" do
    mail = AccountingMailer.gst_report("AU", 3, 2015, "https://test_vat_link.at.s3")
    assert_equal "Australia GST report for Q3 2015", mail.subject
  end

  test "gst_report sends to team" do
    mail = AccountingMailer.gst_report("AU", 3, 2015, "https://test_vat_link.at.s3")
    assert_equal [ApplicationMailer::PAYMENTS_EMAIL], mail.to
  end

  # --- #funds_received_report ------------------------------------------------

  test "funds_received_report sends an email with html body and csv attachment" do
    last_month = Time.current.last_month
    email = AccountingMailer.funds_received_report(last_month.month, last_month.year)
    assert_equal 2, email.body.parts.size
    content_types = email.body.parts.collect(&:content_type)
    assert_includes content_types, "text/html; charset=UTF-8"
    assert(content_types.any? { |ct| ct.include?("text/csv") && ct.include?("funds-received-report-#{last_month.month}-#{last_month.year}.csv") })
    html_body = email.body.parts.find { |part| part.content_type.include?("html") }.body.to_s
    assert_includes html_body, "Funds Received Report"
    assert_includes html_body, "Sales"
    assert_includes html_body, "total_transaction_cents"
  end

  # --- #deferred_refunds_report ---------------------------------------------

  test "deferred_refunds_report sends an email with html body and csv attachment" do
    last_month = Time.current.last_month
    email = AccountingMailer.deferred_refunds_report(last_month.month, last_month.year)
    assert_equal 2, email.body.parts.size
    content_types = email.body.parts.collect(&:content_type)
    assert_includes content_types, "text/html; charset=UTF-8"
    assert(content_types.any? { |ct| ct.include?("text/csv") && ct.include?("deferred-refunds-report-#{last_month.month}-#{last_month.year}.csv") })
    html_body = email.body.parts.find { |part| part.content_type.include?("html") }.body.to_s
    assert_includes html_body, "Deferred Refunds Report"
    assert_includes html_body, "Sales"
    assert_includes html_body, "total_transaction_cents"
  end

  # --- #stripe_currency_balances_report -------------------------------------

  test "stripe_currency_balances_report sends an email with balances report attached as csv" do
    last_month = Time.current.last_month
    balances_csv = "Currency,Balance\nusd,997811.63\n"
    email = AccountingMailer.stripe_currency_balances_report(balances_csv)
    assert_equal 2, email.body.parts.size
    content_types = email.body.parts.collect(&:content_type)
    assert_includes content_types, "text/html; charset=UTF-8"
    assert(content_types.any? { |ct| ct.include?("text/csv") && ct.include?("stripe_currency_balances_#{last_month.month}_#{last_month.year}.csv") })
    html_body = email.body.parts.find { |part| part.content_type.include?("html") }.body.to_s
    assert_includes html_body, "Stripe currency balances CSV is attached."
    assert_includes html_body, "These are the currency balances for Gumroad's Stripe platform account."
  end

  # --- #email_outstanding_balances_csv --------------------------------------

  test "email_outstanding_balances_csv goes to payments and accounting, has zeroed totals when no users" do
    original = User.method(:holding_non_zero_balance)
    User.define_singleton_method(:holding_non_zero_balance) { User.none }
    begin
      mail = AccountingMailer.email_outstanding_balances_csv
      assert_equal [ApplicationMailer::PAYMENTS_EMAIL], mail.to
      assert_equal %w[solson@earlygrowthfinancialservices.com ndelgado@earlygrowthfinancialservices.com], mail.cc
      assert_equal "Outstanding balances", mail.subject
      html_part = mail.body.parts.find { |p| p.content_type.include?("html") }
      body = html_part.body.to_s
      assert_includes body, "Total Outstanding Balances for Paypal: Active $0.0, Suspended $0.0"
      assert_includes body, "Total Outstanding Balances for Stripe(Held by Gumroad): Active $0.0, Suspended $0.0"
      assert_includes body, "Total Outstanding Balances for Stripe(Held by Stripe): Active $0.0, Suspended $0.0"
      assert_equal 1, mail.attachments.length
      assert_equal "outstanding_balances.csv", mail.attachments[0].filename
    ensure
      User.define_singleton_method(:holding_non_zero_balance, original)
    end
  end

  # --- #us_states_sales_summary_report_failed --------------------------------

  test "us_states_sales_summary_report_failed sends to the payments notification email" do
    mail = AccountingMailer.us_states_sales_summary_report_failed(
      ["WA", "WI"], 4, 2026, "ActiveRecord::StatementTimeout", "maximum statement execution time exceeded"
    )
    assert_equal [PAYMENTS_NOTIFICATION_EMAIL], mail.to
  end

  test "us_states_sales_summary_report_failed includes the period in the subject" do
    mail = AccountingMailer.us_states_sales_summary_report_failed(
      ["WA", "WI"], 4, 2026, "ActiveRecord::StatementTimeout", "maximum statement execution time exceeded"
    )
    assert_includes mail.subject, "US States Sales Summary Report failed - 4/2026"
  end

  test "us_states_sales_summary_report_failed does not tag non-TaxJar errors in the subject" do
    mail = AccountingMailer.us_states_sales_summary_report_failed(
      ["WA", "WI"], 4, 2026, "ActiveRecord::StatementTimeout", "maximum statement execution time exceeded"
    )
    refute_includes mail.subject, "[TaxJar]"
  end

  test "us_states_sales_summary_report_failed tags TaxJar errors in the subject" do
    taxjar_mail = AccountingMailer.us_states_sales_summary_report_failed(
      ["WA", "WI"], 4, 2026, "Taxjar::Error::ServerError", "Couldn't parse response as JSON."
    )
    assert_includes taxjar_mail.subject, "[TaxJar] US States Sales Summary Report failed - 4/2026"
  end

  test "us_states_sales_summary_report_failed includes the failure context in the body" do
    mail = AccountingMailer.us_states_sales_summary_report_failed(
      ["WA", "WI"], 4, 2026, "ActiveRecord::StatementTimeout", "maximum statement execution time exceeded"
    )
    body = mail.body.encoded
    assert_includes body, "4/2026"
    assert_includes body, "WA, WI"
    assert_includes body, "ActiveRecord::StatementTimeout"
    assert_includes body, "maximum statement execution time exceeded"
  end

  # --- #ytd_sales_report -----------------------------------------------------

  test "ytd_sales_report sends to the correct recipient" do
    csv_data = "country,state,sales\\nUSA,CA,100\\nUSA,NY,200"
    mail = AccountingMailer.ytd_sales_report(csv_data, "test@example.com")
    assert_equal ["test@example.com"], mail.to
  end

  test "ytd_sales_report has the correct subject" do
    mail = AccountingMailer.ytd_sales_report("a,b,c", "test@example.com")
    assert_equal "Year-to-Date Sales Report by Country/State", mail.subject
  end

  test "ytd_sales_report attaches the CSV file" do
    csv_data = "country,state,sales\\nUSA,CA,100\\nUSA,NY,200"
    mail = AccountingMailer.ytd_sales_report(csv_data, "test@example.com")
    assert_equal 1, mail.attachments.length
    attachment = mail.attachments[0]
    assert_equal "ytd_sales_by_country_state.csv", attachment.filename
    assert_equal "text/csv; filename=ytd_sales_by_country_state.csv", attachment.content_type
    assert_equal csv_data, Base64.decode64(attachment.body.encoded)
  end
end
