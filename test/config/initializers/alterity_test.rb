# frozen_string_literal: true

require "test_helper"

class AlterityConfigurationTest < ActiveSupport::TestCase
  setup do
    @command = Alterity.config.command.call("users", "DROP COLUMN twitter_handle")
  end

  test "includes --preserve-triggers so migrations succeed on tables with existing triggers" do
    assert_includes @command, "--preserve-triggers"
  end

  test "includes the altered table and alter argument" do
    assert_includes @command, "t=users"
    assert_includes @command, "--alter DROP COLUMN twitter_handle"
  end
end
