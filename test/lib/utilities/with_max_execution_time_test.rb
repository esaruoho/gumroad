require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration:
# This spec exercises MySQL MAX_EXECUTION_TIME hints through the Makara
# connection proxy and reliably poisons the Makara test connection, breaking
# unrelated tests that run afterward. Needs an isolated test process or
# Makara teardown to migrate safely.
#
# Original spec: spec/lib/utilities/with_max_execution_time_spec.rb (deleted in this commit)
class WithMaxExecutionTimeTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — Makara-poisoning, needs isolation" do
    skip "TODO: migrate spec/lib/utilities/with_max_execution_time_spec.rb — poisons Makara connection"
  end
end
