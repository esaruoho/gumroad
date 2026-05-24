# frozen_string_literal: true

require "test_helper"

class ReplicaLagWatcherTest < ActiveSupport::TestCase
  def teardown
    Thread.current["ReplicaLagWatcher.connections"] = nil
    Thread.current["ReplicaLagWatcher.last_checked_at"] = nil
  end

  # ----- .watch -----

  test ".watch sleeps if a replica is lagging" do
    with_const(:REPLICAS_HOSTS, [Object.new]) do
      sleep_calls = 0
      lagging_returns = [true, true, false]

      ReplicaLagWatcher.stub(:connect_to_replicas, nil) do
        ReplicaLagWatcher.stub(:lagging?, ->(*) { lagging_returns.shift }) do
          ReplicaLagWatcher.stub(:sleep, ->(s) { assert_equal 1, s; sleep_calls += 1 }) do
            ReplicaLagWatcher.watch(silence: true)
          end
        end
      end
      assert_equal 2, sleep_calls
    end
  end

  test ".watch does nothing if there are no replicas" do
    with_const(:REPLICAS_HOSTS, []) do
      called = false
      ReplicaLagWatcher.stub(:lagging?, ->(*) { called = true }) do
        ReplicaLagWatcher.watch
      end
      refute called
      assert_nil ReplicaLagWatcher.last_checked_at
    end
  end

  # ----- .lagging? -----

  def lagging_options
    { check_every: 1.second, max_lag_allowed: 1.second, silence: true }
  end

  def fake_connection(seconds_behind_master)
    conn = Object.new
    conn.define_singleton_method(:query_options) { { host: "replica.host" } }
    conn.define_singleton_method(:query) do |sql|
      raise "unexpected query: #{sql}" unless sql == "SHOW SLAVE STATUS"
      [{ "Seconds_Behind_Master" => seconds_behind_master }]
    end
    conn
  end

  test ".lagging? sets last_checked_at" do
    ReplicaLagWatcher.connections = []
    ReplicaLagWatcher.stub(:check_for_lag?, true) do
      ReplicaLagWatcher.lagging?(lagging_options)
    end
    assert_kind_of Float, ReplicaLagWatcher.last_checked_at
  end

  test ".lagging? returns true if one of the replica connections is lagging" do
    ReplicaLagWatcher.connections = [fake_connection(2)]
    ReplicaLagWatcher.stub(:check_for_lag?, true) do
      assert_equal true, ReplicaLagWatcher.lagging?(lagging_options)
    end
  end

  test ".lagging? returns false if no connections are lagging" do
    ReplicaLagWatcher.connections = [fake_connection(0)]
    ReplicaLagWatcher.stub(:check_for_lag?, true) do
      assert_equal false, ReplicaLagWatcher.lagging?(lagging_options)
    end
  end

  test ".lagging? raises an error if the lag can't be determined" do
    ReplicaLagWatcher.connections = [fake_connection(nil)]
    ReplicaLagWatcher.stub(:check_for_lag?, true) do
      err = assert_raises(RuntimeError) { ReplicaLagWatcher.lagging?(lagging_options) }
      assert_match(/lag = null/, err.message)
    end
  end

  test ".lagging? returns nil if it doesn't need to check for lag" do
    ReplicaLagWatcher.connections = []
    ReplicaLagWatcher.stub(:check_for_lag?, false) do
      assert_nil ReplicaLagWatcher.lagging?(lagging_options)
    end
  end

  # ----- .check_for_lag? -----

  test ".check_for_lag? returns true if it was never checked before" do
    assert_equal true, ReplicaLagWatcher.check_for_lag?(1)
  end

  test ".check_for_lag? returns true/false depending on elapsed time" do
    check_every = 1
    ReplicaLagWatcher.last_checked_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    assert_equal false, ReplicaLagWatcher.check_for_lag?(check_every)
    sleep 1
    assert_equal true, ReplicaLagWatcher.check_for_lag?(check_every)
  end

  # ----- .connect_to_replicas -----

  test ".connect_to_replicas does not set new connections if some exist already" do
    existing = [Object.new]
    ReplicaLagWatcher.connections = existing
    ReplicaLagWatcher.connect_to_replicas
    assert_equal existing, ReplicaLagWatcher.connections
  end

  test ".connect_to_replicas sets connections if they weren't set before" do
    with_const(:REPLICAS_HOSTS, ["web-replica-1.aaaaaa.us-east-1.rds.amazonaws.com"]) do
      connection_double = Object.new
      cfg = ActiveRecord::Base.connection_db_config.configuration_hash
      captured_args = nil
      stub_new = ->(**kwargs) { captured_args = kwargs; connection_double }
      Mysql2::Client.stub(:new, stub_new) do
        ReplicaLagWatcher.connect_to_replicas
      end
      assert_equal({
        host: "web-replica-1.aaaaaa.us-east-1.rds.amazonaws.com",
        username: cfg[:username],
        password: cfg[:password],
        database: cfg[:database],
      }, captured_args)
      assert_equal [connection_double], ReplicaLagWatcher.connections
    end
  end
end
