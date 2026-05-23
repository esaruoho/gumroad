# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration
# because it relies on Elasticsearch (`index_model_records(Installment)` and
# `Installment.search(...)`), which is out of scope for the fixture-only pass.
# Revisit when Elasticsearch test-harness is wired into Minitest.
#
# Original spec: spec/services/installment_search_service_spec.rb
class InstallmentSearchServiceTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — requires Elasticsearch test harness" do
    skip "TODO: migrate spec/services/installment_search_service_spec.rb (Elasticsearch-bound)"
  end
end
