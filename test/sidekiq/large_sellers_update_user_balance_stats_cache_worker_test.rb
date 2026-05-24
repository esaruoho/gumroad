# frozen_string_literal: true

require "test_helper"

class LargeSellersUpdateUserBalanceStatsCacheWorkerTest < ActiveSupport::TestCase
  test "queues a job for each cacheable user" do
    user_a = users(:named_seller)
    user_b = users(:another_seller)
    ids = [user_a.id, user_b.id]

    UpdateUserBalanceStatsCacheWorker.clear

    UserBalanceStatsService.stub(:cacheable_users, User.where(id: ids)) do
      LargeSellersUpdateUserBalanceStatsCacheWorker.new.perform
    end

    enqueued_args = UpdateUserBalanceStatsCacheWorker.jobs.map { |j| j["args"] }
    assert_includes enqueued_args, [user_a.id]
    assert_includes enqueued_args, [user_b.id]
  end
end
