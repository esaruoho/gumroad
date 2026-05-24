# frozen_string_literal: true

require "test_helper"

class ElasticsearchIndexerWorkerTest < ActiveSupport::TestCase
  test "skipped: requires real Elasticsearch" do
    skip "ElasticsearchIndexerWorker spec exercises real EsClient index/get/update/scroll operations. The global test_helper EsClient fake returns no-op stubs, making the assertions meaningless. Covered by RSpec."
  end
end
