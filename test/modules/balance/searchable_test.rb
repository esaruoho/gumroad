# frozen_string_literal: true

require "test_helper"

class BalanceSearchableTest < ActiveSupport::TestCase
  test "includes ElasticsearchModelAsyncCallbacks" do
    assert_includes Balance.ancestors, ElasticsearchModelAsyncCallbacks
  end
end
