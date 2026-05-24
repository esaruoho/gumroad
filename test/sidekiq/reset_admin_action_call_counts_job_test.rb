# frozen_string_literal: true

require "test_helper"

class ResetAdminActionCallCountsJobTest < ActiveSupport::TestCase
  test "recreates admin action call infos" do
    # Existing fixtures already provide a call-count > 0 row (dashboard_calls).
    AdminActionCallInfo.create!(controller_name: "NoLongerExistingController", action_name: "index", call_count: 3)

    ResetAdminActionCallCountsJob.new.perform

    assert AdminActionCallInfo.where(action_name: "index").exists?
    assert_empty AdminActionCallInfo.where("call_count > 0")
    assert_empty AdminActionCallInfo.where(controller_name: "NoLongerExistingController")
  end
end
