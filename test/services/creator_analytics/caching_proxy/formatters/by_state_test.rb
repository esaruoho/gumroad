# frozen_string_literal: true

require "test_helper"

class CreatorAnalytics::CachingProxy::Formatters::ByStateTest < ActiveSupport::TestCase
  setup do
    @service = CreatorAnalytics::CachingProxy.new(users(:named_seller))
  end

  test "#merge_data_by_state returns data merged by state across days" do
    day_one = {
      by_state: {
        views:  { "tPsrl" => { "Canada" => 1, "United States" => [1, 1, 1, 1], "France" => 1 }, "PruAb" => { "Canada" => 1 } },
        sales:  { "tPsrl" => { "Canada" => 1 }, "PruAb" => { "Canada" => 1 } },
        totals: { "tPsrl" => { "Canada" => 1 }, "PruAb" => { "Canada" => 1 } },
      }
    }
    # New format + new product on day_two
    day_two = {
      by_state: {
        views:  { "tPsrl" => { "Canada" => 1, "United States" => [1, 1, 1, 1], "France" => 1 }, "PruAb" => { "Brazil" => 1 }, "Mmwrc" => { "United States" => [1, 1, 1, 1], "Brazil" => 1 } },
        sales:  { "tPsrl" => { "Canada" => 1 }, "PruAb" => { "Canada" => 1 }, "Mmwrc" => { "United States" => [1, 1, 1, 1], "Canada" => 1 } },
        totals: { "tPsrl" => { "Canada" => 1 }, "PruAb" => { "Canada" => 1 }, "Mmwrc" => { "France" => 1 } },
      }
    }

    expected = {
      by_state: {
        views:  { "tPsrl" => { "Canada" => 2, "United States" => [2, 2, 2, 2], "France" => 2 }, "PruAb" => { "Canada" => 1, "Brazil" => 1 }, "Mmwrc" => { "United States" => [1, 1, 1, 1], "Brazil" => 1 } },
        sales:  { "tPsrl" => { "Canada" => 2 }, "PruAb" => { "Canada" => 2 }, "Mmwrc" => { "United States" => [1, 1, 1, 1], "Canada" => 1 } },
        totals: { "tPsrl" => { "Canada" => 2 }, "PruAb" => { "Canada" => 2 }, "Mmwrc" => { "France" => 1 } }
      }
    }

    result = @service.merge_data_by_state([day_one, day_two])
    assert_equal expected.deep_stringify_keys, result.deep_stringify_keys
  end
end
