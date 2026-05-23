# frozen_string_literal: true

require "test_helper"

class HandleNewUserComplianceInfoWorkerTest < ActiveSupport::TestCase
  test "calls StripeMerchantAccountManager.handle_new_user_compliance_info with the user compliance info object" do
    info = user_compliance_info(:tax_summary_payable_compliance_info)

    captured = nil
    StripeMerchantAccountManager.stub(:handle_new_user_compliance_info, ->(arg) { captured = arg }) do
      HandleNewUserComplianceInfoWorker.new.perform(info.id)
    end

    assert_equal info, captured
  end
end
