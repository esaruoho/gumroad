require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration:
# DevTools requires a running Elasticsearch instance and exercises real ES
# index lifecycle. Migration deferred until the test suite has a documented
# ES bootstrap path (or the tests are rewritten against a stub).
#
# Original spec: spec/lib/utilities/dev_tools_spec.rb (deleted in this commit)
class DevToolsTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — requires Elasticsearch" do
    skip "TODO: migrate spec/lib/utilities/dev_tools_spec.rb — requires Elasticsearch"
  end
end
