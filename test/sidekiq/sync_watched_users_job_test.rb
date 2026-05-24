# frozen_string_literal: true

require "test_helper"

class SyncWatchedUsersJobTest < ActiveSupport::TestCase
  setup do
    @prepended_modules = []
  end

  teardown do
    @prepended_modules.each { |mod, _klass| mod.module_eval { instance_methods(false).each { |m| remove_method(m) } } }
  end

  def stub_instance_method(klass, method, &block)
    mod = Module.new
    mod.send(:define_method, method, &block)
    klass.prepend(mod)
    @prepended_modules << [mod, klass]
  end

  test "syncs every alive watched user" do
    alive_watch = watched_users(:alive_watch_one)
    other_alive_watch = watched_users(:alive_watch_two)
    deleted_watch = watched_users(:deleted_watch)

    stub_instance_method(WatchedUser, :sync!) do
      update!(last_synced_at: Time.current)
    end

    SyncWatchedUsersJob.new.perform

    refute_nil alive_watch.reload.last_synced_at
    refute_nil other_alive_watch.reload.last_synced_at
    assert_nil deleted_watch.reload.last_synced_at
  end

  test "notifies on per-record errors but continues processing" do
    first = watched_users(:alive_watch_one)
    second = watched_users(:alive_watch_two)

    stub_instance_method(WatchedUser, :sync!) do
      if id == first.id
        raise StandardError, "boom"
      else
        update!(revenue_cents: 0, unpaid_balance_cents: 0, last_synced_at: Time.current)
      end
    end

    notified = []
    ErrorNotifier.stub(:notify, ->(e, **ctx) { notified << [e, ctx] }) do
      SyncWatchedUsersJob.new.perform
    end

    assert_equal 1, notified.size
    assert_instance_of StandardError, notified.first.first
    assert_equal({ context: { watched_user_id: first.id } }, notified.first.last)
    refute_nil second.reload.last_synced_at
  end
end
