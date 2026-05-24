# frozen_string_literal: true

require "test_helper"

class CustomDomainsVerificationWorkerTest < ActiveSupport::TestCase
  setup do
    CustomDomainVerificationWorker.clear
  end

  test "verifies every non-deleted, non-exhausted domain in its own background job" do
    cd_one = custom_domains(:cdvw_unverified_one)
    cd_two = custom_domains(:cdvw_too_many_failures)
    cd_three = custom_domains(:cdvw_verified)
    cd_four = custom_domains(:cdvw_deleted)
    cd_five = custom_domains(:cdvw_under_limit)

    CustomDomainsVerificationWorker.new.perform

    enqueued_ids = CustomDomainVerificationWorker.jobs.map { |j| j["args"].first }
    assert_includes enqueued_ids, cd_one.id
    refute_includes enqueued_ids, cd_two.id
    assert_includes enqueued_ids, cd_three.id
    refute_includes enqueued_ids, cd_four.id
    assert_includes enqueued_ids, cd_five.id
  end
end
