# frozen_string_literal: true

require "test_helper"

class MysqlMissingTableHandlerTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  test "retries query if table is missing" do
    client = ActiveRecord::Base.connection_db_config
      .configuration_hash
      .slice(*%i[host username password database port socket encoding])
      .then { |conf| Mysql2::Client.new(conf) }

    original_grace = Mysql2::Client::MISSING_TABLE_GRACE_PERIOD
    Mysql2::Client.send(:remove_const, :MISSING_TABLE_GRACE_PERIOD)
    Mysql2::Client.const_set(:MISSING_TABLE_GRACE_PERIOD, 2)

    client.query("DROP TABLE IF EXISTS `foo`, `bar`")
    client.query("CREATE TABLE `bar` (id int)")
    client.query("INSERT INTO `bar`(id) VALUES (1),(2),(3)")

    Thread.new do
      sleep 1
      client.query("RENAME TABLE `bar` TO `foo`")
    end

    values = nil
    _out, err = capture_io do
      result = client.query("SELECT id FROM `foo`")
      values = result.map { |row| row["id"].to_i }
    end

    assert_match(/Error: missing table, retrying in/, err)
    assert_equal [1, 2, 3], values.sort
  ensure
    if defined?(original_grace) && original_grace
      Mysql2::Client.send(:remove_const, :MISSING_TABLE_GRACE_PERIOD)
      Mysql2::Client.const_set(:MISSING_TABLE_GRACE_PERIOD, original_grace)
    end
    client&.query("DROP TABLE IF EXISTS `foo`, `bar`") rescue nil
    client&.close rescue nil
  end
end
