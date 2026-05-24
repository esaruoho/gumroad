# frozen_string_literal: true

require "test_helper"

# JSErrorReporter is defined in spec/support/js_error_reporter.rb. The original
# RSpec test spun up Selenium Chrome and exercised the full driver round-trip;
# CI's Minitest job has no Chrome, so we load the class directly and unit-test
# the parser against synthesized DevTools log messages instead. That covers the
# only non-trivial code in the class (read_errors!), since everything else is
# accessor/state plumbing.
require Rails.root.join("spec", "support", "js_error_reporter")

class JsErrorReporterTest < ActiveSupport::TestCase
  LogEntry = Struct.new(:message)

  class FakeLogs
    def initialize(entries) = @entries = entries
    def get(_type) = @entries
  end

  class FakeDriver
    def initialize(entries) = @entries = entries
    def logs = FakeLogs.new(@entries)
  end

  setup do
    JSErrorReporter.enabled = true
    @reporter = JSErrorReporter.new
  end

  teardown { JSErrorReporter.enabled = nil }

  def exception_thrown(message:, url: "file:///t.html", line: 3, col: 16, stack: nil)
    payload = {
      "exceptionDetails" => {
        "exception" => { "value" => message },
        "url" => url,
        "lineNumber" => line,
        "columnNumber" => col,
        "stackTrace" => stack
      }
    }
    LogEntry.new("DevTools WebSocket Event: Runtime.exceptionThrown #{payload.to_json}")
  end

  def console_error(args:, stack: nil)
    payload = { "type" => "error", "args" => args, "stackTrace" => stack }
    LogEntry.new("DevTools WebSocket Event: Runtime.consoleAPICalled #{payload.to_json}")
  end

  def console_log(args:)
    payload = { "type" => "log", "args" => args, "stackTrace" => nil }
    LogEntry.new("DevTools WebSocket Event: Runtime.consoleAPICalled #{payload.to_json}")
  end

  test "returns no errors when JSErrorReporter is disabled" do
    JSErrorReporter.enabled = false
    driver = FakeDriver.new([exception_thrown(message: "boom")])
    assert_equal [], @reporter.read_errors!(driver)
  end

  test "formats a thrown Error with no stack trace into a single-line trace" do
    driver = FakeDriver.new([exception_thrown(message: "Cannot add", stack: nil)])
    errors = @reporter.read_errors!(driver)
    assert_equal 1, errors.size
    assert_equal "Error: Cannot add\n\tat file:///t.html:3:16", errors[0]
  end

  test "formats a thrown Error with a stack trace using callFrames" do
    stack = {
      "callFrames" => [
        { "functionName" => "add", "url" => "file:///t.html", "lineNumber" => 3, "columnNumber" => 16 }
      ]
    }
    driver = FakeDriver.new([exception_thrown(message: "Cannot add", stack: stack)])
    errors = @reporter.read_errors!(driver)
    assert_equal "Error: Cannot add\n\tadd (file:///t.html:3:16)", errors[0]
  end

  test "formats console.error entries with mixed primitive/object args" do
    args = [
      { "type" => "string", "value" => "Test error log" },
      { "type" => "number", "value" => 42 },
      { "type" => "object", "subtype" => "array", "className" => "Array",
        "preview" => { "properties" => [
          { "type" => "object", "subtype" => "null" },
          { "type" => "boolean", "value" => "false" }
        ] } },
      { "type" => "object", "className" => "Object",
        "preview" => { "properties" => [
          { "name" => "x", "type" => "number", "value" => 1 }
        ] } }
    ]
    stack = { "callFrames" => [{ "functionName" => "", "url" => "file:///t.html", "lineNumber" => 2, "columnNumber" => 16 }] }
    driver = FakeDriver.new([console_error(args: args, stack: stack)])
    errors = @reporter.read_errors!(driver)
    assert_equal 1, errors.size
    line, first_trace = errors[0].split("\n")
    assert_equal %{Console error: Test error log, 42, [null,false], {"x":1}}, line
    assert_equal "\t (file:///t.html:2:16)", first_trace
  end

  test "ignores console.log and console.warn (only :error type bubbles up)" do
    driver = FakeDriver.new([
      console_log(args: [{ "type" => "string", "value" => "info" }])
    ])
    assert_equal [], @reporter.read_errors!(driver)
  end

  test "respects one-off ignore patterns added via add_ignore_error" do
    driver = FakeDriver.new([exception_thrown(message: "Cannot add", stack: nil)])
    @reporter.add_ignore_error(/Cannot add/)
    assert_equal [], @reporter.read_errors!(driver)
  end

  test "respects global ignore patterns set via set_global_ignores" do
    original_globals = JSErrorReporter.global_patterns
    JSErrorReporter.set_global_ignores([/Cannot add/])
    begin
      driver = FakeDriver.new([exception_thrown(message: "Cannot add", stack: nil)])
      assert_equal [], @reporter.read_errors!(driver)
    ensure
      JSErrorReporter.set_global_ignores(original_globals)
    end
  end

  test "add_ignore_error appends to the per-instance ignore list and reset! clears it" do
    @reporter.add_ignore_error("boom")
    @reporter.reset!
    driver = FakeDriver.new([exception_thrown(message: "boom", stack: nil)])
    refute_empty @reporter.read_errors!(driver)
  end

  test "enabled? falls back to the ENABLE_RAISE_JS_ERROR env var when unset" do
    JSErrorReporter.enabled = nil
    ENV["ENABLE_RAISE_JS_ERROR"] = "1"
    begin
      assert JSErrorReporter.enabled?
    ensure
      ENV.delete("ENABLE_RAISE_JS_ERROR")
    end
  end
end
