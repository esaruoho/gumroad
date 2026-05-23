# frozen_string_literal: true

require "test_helper"

class EmailOutstandingBalancesCsvWorkerTest < ActiveSupport::TestCase
  test "enqueues AccountingMailer.email_outstanding_balances_csv" do
    Rails.env.stub(:production?, true) do
      mailer_double = Minitest::Mock.new
      mailer_double.expect(:deliver_now, nil)

      AccountingMailer.stub(:email_outstanding_balances_csv, mailer_double) do
        EmailOutstandingBalancesCsvWorker.new.perform
      end

      assert mailer_double.verify
    end
  end
end
