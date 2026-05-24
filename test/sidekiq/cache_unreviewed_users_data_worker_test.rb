# frozen_string_literal: true

require "test_helper"

class CacheUnreviewedUsersDataWorkerTest < ActiveSupport::TestCase
  test "delegates to Admin::UnreviewedUsersService.cache_users_data!" do
    called = false
    Admin::UnreviewedUsersService.stub(:cache_users_data!, -> { called = true; {} }) do
      CacheUnreviewedUsersDataWorker.new.perform
    end
    assert called
  end
end
