# frozen_string_literal: true

require "test_helper"

class SendStripeCurrencyBalancesReportJobTest < ActiveSupport::TestCase
  test "enqueues AccountingMailer.stripe_currency_balances_report" do
    mailer_double = Minitest::Mock.new
    mailer_double.expect(:deliver_now, nil)

    called = false
    Rails.env.stub(:production?, true) do
      StripeCurrencyBalancesReport.stub(:stripe_currency_balances_report, "Currency,Balance\nusd,997811.63\n") do
        AccountingMailer.stub(:stripe_currency_balances_report, ->(*) { called = true; mailer_double }) do
          SendStripeCurrencyBalancesReportJob.new.perform
        end
      end
    end

    assert called
    assert mailer_double.verify
  end
end
