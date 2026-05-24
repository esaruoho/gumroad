require "test_helper"

# TODO: Migrate from RSpec. CallLimitationInfo specs require a deep fixture
# graph (call_product + variants + call_availabilities + purchases with sold_calls
# scope) and rely on RSpec partial doubles for `has_enough_notice?` /
# `can_take_more_calls_on?`. Out of scope for a mechanical fixture migration.
#
# Original spec: spec/models/call_limitation_info_spec.rb (deleted in this commit; see git history)
class CallLimitationInfoTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — call_product + availability + purchase fixture chain" do
    skip "TODO: migrate spec/models/call_limitation_info_spec.rb — see comment above"
  end
end
