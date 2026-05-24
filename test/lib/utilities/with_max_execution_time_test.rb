# frozen_string_literal: true

require "test_helper"

class WithMaxExecutionTimeTest < ActiveSupport::TestCase
  # test_helper.rb installs a stub that makes `timeout_queries` just `yield`
  # (because the real method issues `SET SESSION max_execution_time = …` on
  # the AR connection, which poisons Makara in CI). For this file alone we
  # reload the real implementation, exercise it against a fake connection,
  # then restore the stub in teardown so we don't poison other tests.
  setup do
    @stub_method = WithMaxExecutionTime.singleton_class.instance_method(:timeout_queries)
    load Rails.root.join("lib", "utilities", "with_max_execution_time.rb").to_s
  end

  teardown do
    stub = @stub_method
    WithMaxExecutionTime.define_singleton_method(:timeout_queries) do |seconds:, &block|
      stub.bind(WithMaxExecutionTime).call(seconds: seconds, &block)
    end
  end

  # Build a fake AR connection that records execute() calls. Optionally
  # raise Mysql2::Error on the Nth `set max_execution_time` call to simulate
  # the connection dying mid-restore.
  class FakeConnection
    attr_reader :statements

    def initialize(fail_set_after: nil)
      @statements = []
      @fail_set_after = fail_set_after
      @set_count = 0
    end

    def execute(sql, *args)
      @statements << sql
      if sql.start_with?("set max_execution_time")
        @set_count += 1
        raise Mysql2::Error, "MySQL server has gone away" if @fail_set_after && @set_count > @fail_set_after
        return nil
      end
      if sql == "select @@max_execution_time"
        # Mimic the [[value]] shape AR returns for raw SELECTs.
        return [[0]]
      end
      nil
    end
  end

  def with_fake_connection(connection)
    original = ActiveRecord::Base.method(:connection)
    ActiveRecord::Base.define_singleton_method(:connection) { connection }
    yield
  ensure
    ActiveRecord::Base.singleton_class.send(:remove_method, :connection)
    ActiveRecord::Base.define_singleton_method(:connection, original)
  end

  test ".timeout_queries returns the block's value when nothing raises" do
    connection = FakeConnection.new
    returned = with_fake_connection(connection) do
      WithMaxExecutionTime.timeout_queries(seconds: 5) do
        connection.execute("select 1")
        :foo
      end
    end
    assert_equal :foo, returned
    # SET → block-select → restore SET
    assert_includes connection.statements, "set max_execution_time = 5000"
    assert_includes connection.statements, "select 1"
  end

  test ".timeout_queries raises QueryTimeoutError when StatementInvalid mentions the timeout text" do
    connection = FakeConnection.new
    with_fake_connection(connection) do
      assert_raises(WithMaxExecutionTime::QueryTimeoutError) do
        WithMaxExecutionTime.timeout_queries(seconds: 0.001) do
          raise ActiveRecord::StatementInvalid.new(
            "Mysql2::Error: Query execution was interrupted, maximum statement execution time exceeded"
          )
        end
      end
    end
  end

  test ".timeout_queries re-raises StatementInvalid errors unrelated to the timeout" do
    connection = FakeConnection.new
    with_fake_connection(connection) do
      assert_raises(ActiveRecord::StatementInvalid) do
        WithMaxExecutionTime.timeout_queries(seconds: 5) do
          raise ActiveRecord::StatementInvalid.new("some other failure")
        end
      end
    end
  end

  test ".timeout_queries does not mask QueryTimeoutError when restoring max_execution_time fails" do
    connection = FakeConnection.new(fail_set_after: 1)
    with_fake_connection(connection) do
      assert_raises(WithMaxExecutionTime::QueryTimeoutError) do
        WithMaxExecutionTime.timeout_queries(seconds: 0.001) do
          raise ActiveRecord::StatementInvalid.new(
            "Mysql2::Error: Query execution was interrupted, maximum statement execution time exceeded"
          )
        end
      end
    end
  end

  test ".timeout_queries logs when restoring max_execution_time fails" do
    connection = FakeConnection.new(fail_set_after: 1)
    logged = []
    original_logger = Rails.logger
    fake_logger = Object.new
    fake_logger.define_singleton_method(:error) { |msg| logged << msg }
    # Pass other logger methods through to the real logger so nothing else breaks.
    fake_logger.define_singleton_method(:method_missing) { |name, *args, &blk| original_logger.public_send(name, *args, &blk) if original_logger.respond_to?(name) }
    fake_logger.define_singleton_method(:respond_to_missing?) { |_n, _p = false| true }

    Rails.logger = fake_logger
    begin
      with_fake_connection(connection) do
        assert_raises(WithMaxExecutionTime::QueryTimeoutError) do
          WithMaxExecutionTime.timeout_queries(seconds: 0.001) do
            raise ActiveRecord::StatementInvalid.new(
              "Mysql2::Error: Query execution was interrupted, maximum statement execution time exceeded"
            )
          end
        end
      end
    ensure
      Rails.logger = original_logger
    end

    assert logged.any? { |m| m =~ /\[WithMaxExecutionTime\] Failed to restore max_execution_time.*MySQL server has gone away/ },
           "expected restoration-failure log line, got: #{logged.inspect}"
  end
end
