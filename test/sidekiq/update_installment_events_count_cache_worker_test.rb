# frozen_string_literal: true

require "test_helper"

class UpdateInstallmentEventsCountCacheWorkerTest < ActiveSupport::TestCase
  test "calculates and caches the correct installment_events count" do
    installment = installments(:published_post)
    UpdateInstallmentEventsCountCacheWorker.new.perform(installment.id)
    installment.reload
    assert_equal 2, installment.installment_events_count
  end
end
