# frozen_string_literal: true

require "test_helper"

class SendFinancesReportWorkerTest < ActiveSupport::TestCase
  test "enqueues AccountingMailer.funds_received_report" do
    last_month = Time.current.last_month
    mailer_double = Minitest::Mock.new
    mailer_double.expect(:deliver_now, nil)

    captured = nil
    Rails.env.stub(:production?, true) do
      AccountingMailer.stub(:funds_received_report, ->(m, y) { captured = [m, y]; mailer_double }) do
        SendFinancesReportWorker.new.perform
      end
    end

    assert_equal [last_month.month, last_month.year], captured
    assert mailer_double.verify
  end
end
