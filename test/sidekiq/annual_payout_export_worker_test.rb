# frozen_string_literal: true

require "test_helper"

class AnnualPayoutExportWorkerTest < ActiveSupport::TestCase
  test "skipped: ActiveStorage attach + mailer chain" do
    skip "AnnualPayoutExportWorker calls user.annual_reports.attach (ActiveStorage) and ContactingCreatorMailer; deep mailer+storage chain. Covered by RSpec."
  end
end
