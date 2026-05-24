# frozen_string_literal: true

require "test_helper"

class CreatorAnalytics::Churn::DateWindowTest < ActiveSupport::TestCase
  test "TODO: migrate spec/services/creator_analytics/churn/date_window_spec.rb" do
    skip "Requires multi-seller fixtures across two timezones, dynamic Purchase records (first_sale_created_at_for_analytics uses raw SQL UNION over sales) per-test, and memoization assertions via `expect(window).to receive(:start_date).once.and_call_original`. Multiple tests have conflicting setup requirements (one test asserts no sales while another requires a Jan-10 purchase) so fixture-only data wiring is non-trivial."
  end
end
