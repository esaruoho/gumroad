# frozen_string_literal: true

require "spec_helper"

describe JSErrorReporter do
  around do |example|
    JSErrorReporter.enabled = true
    example.run
  ensure
    JSErrorReporter.enabled = nil
  end

  def build_playwright_driver(errors)
    page = Class.new do
      def initialize(errors)
        @errors = errors
      end

      def evaluate(_script)
        @errors.tap { @errors = [] }
      end
    end.new(errors)

    Class.new do
      def initialize(page)
        @page = page
      end

      def with_playwright_page(&block)
        block.call(@page)
      end
    end.new(page)
  end

  def read_errors(errors)
    JSErrorReporter.instance.read_errors!(build_playwright_driver(errors))
  end

  it "reports raised Error exceptions with stack trace" do
    url = "file:///tmp/js_error_reporter_error.html"
    errors = read_errors(["Error: Cannot add\n\tat #{url}:3:16"])

    expect(errors.size).to eq 1
    line, first_trace = errors[0].split("\n")
    expect(line).to eq "Error: Cannot add"
    expect(first_trace).to eq "\tat #{url}:3:16"
  end

  it "reports raised primitive value exceptions" do
    errors = read_errors(["Error: Cannot add"])

    expect(errors).to eq ["Error: Cannot add"]
  end

  it "reports console.error entries with multiple or complex arguments" do
    errors = read_errors([
                           %{Console error: Test error log, 42, [null,false], {"x":1}, {"test":["a","b","c"]}},
                         ])

    expect(errors).to eq [
      %{Console error: Test error log, 42, [null,false], {"x":1}, {"test":["a","b","c"]}},
    ]
  end

  it "does not report console.log and console.warn entries" do
    errors = read_errors([])

    expect(errors).to eq []
  end

  it "reports combinations of errors properly" do
    url = "file:///tmp/js_error_reporter_combination.html"
    errors = read_errors([
                           "Console error: Sample error info",
                           "Error: Cannot add\n\tat #{url}:8:16",
                         ])

    expect(errors.size).to eq 2

    line, = errors[0].split("\n")
    expect(line).to eq "Console error: Sample error info"

    line, first_trace = errors[1].split("\n")
    expect(line).to eq "Error: Cannot add"
    expect(first_trace).to eq "\tat #{url}:8:16"
  end

  it "clears collected errors after reading" do
    driver = build_playwright_driver(["Error: Cannot add"])

    expect(JSErrorReporter.instance.read_errors!(driver)).to eq ["Error: Cannot add"]
    expect(JSErrorReporter.instance.read_errors!(driver)).to eq []
  end

  pending "it presents source-mapped stack traces instead of raw ones"
end
