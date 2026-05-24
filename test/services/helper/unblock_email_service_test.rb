# frozen_string_literal: true

require "test_helper"

class Helper::UnblockEmailServiceTest < ActiveSupport::TestCase
  test "TODO: migrate spec/services/helper/unblock_email_service_spec.rb (extensive allow_any_instance_of on Helper::Client + EmailSuppressionManager)" do
    skip "Awaiting fixtures migration: relies on RSpec any_instance partial-doubles for Helper::Client and EmailSuppressionManager + Feature toggling + PlatformBlock/BlockedCustomerObject fixtures"
  end
end
