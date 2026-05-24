# frozen_string_literal: true

require "test_helper"

class ContentModeration::Strategies::PromptStrategyTest < ActiveSupport::TestCase
  Strategy = ContentModeration::Strategies::PromptStrategy

  test "moderates image-only content" do
    client = FakeChatClient.new(
      json_chat_response(flagged: true, reasoning: "clear adult content"),
      json_chat_response(uncertain: false),
      json_chat_response(flagged: false, reasoning: "")
    )

    with_strategy_stubs(client:) do |openai_calls:, **|
      result = Strategy.new(text: "", image_urls: ["https://cdn.example.com/1.png"]).perform

      assert_equal "flagged", result.status
      assert_equal ["adult_content: clear adult content"], result.reasoning
      assert_equal [{ access_token: "test-key", request_timeout: 10 }], openai_calls
    end
  end

  test "returns compliant when the API key is blank" do
    client = FakeChatClient.new

    with_strategy_stubs(client:, openai_access_token: nil) do |openai_calls:, **|
      result = Strategy.new(text: "moderate me").perform

      assert_equal "compliant", result.status
      assert_equal [], result.reasoning
      assert_empty openai_calls
    end
  end

  test "filters flagged results through the uncertainty check" do
    client = FakeChatClient.new(
      json_chat_response(flagged: true, reasoning: "maybe explicit"),
      json_chat_response(uncertain: true),
      json_chat_response(flagged: true, reasoning: "clear spam"),
      json_chat_response(uncertain: false)
    )

    with_strategy_stubs(client:) do
      result = Strategy.new(text: "moderate me", image_urls: ["https://cdn.example.com/1.png"]).perform

      assert_equal "flagged", result.status
      assert_equal ["spam: clear spam"], result.reasoning
    end
  end

  test "logs and re-raises when the uncertainty check fails" do
    call_count = 0
    client = FakeChatClient.new do
      call_count += 1
      call_count == 1 ? json_chat_response(flagged: true, reasoning: "clear adult content") : raise(StandardError, "judge failure")
    end

    with_strategy_stubs(client:) do |errors:, **|
      error = assert_raises(StandardError) { Strategy.new(text: "moderate me").perform }

      assert_equal "judge failure", error.message
      assert_includes errors, "ContentModeration::PromptStrategy uncertainty check error: judge failure"
    end
  end

  test "logs and re-raises when the OpenAI request fails" do
    client = FakeChatClient.new(StandardError.new("API failure"))

    with_strategy_stubs(client:) do |errors:, **|
      error = assert_raises(StandardError) { Strategy.new(text: "moderate me").perform }

      assert_equal "API failure", error.message
      assert_includes errors, "ContentModeration::PromptStrategy preset evaluation error: API failure"
    end
  end

  test "treats both presets as compliant and reports each OpenAI 400 rejection" do
    client = FakeChatClient.new(bad_request_error, bad_request_error)

    with_strategy_stubs(client:) do |notify_calls:, **|
      result = Strategy.new(
        text: "moderate me",
        image_urls: ["https://files.gumroad.com/bad.psd", "https://cdn.example.com/ok.png"]
      ).perform

      assert_equal "compliant", result.status
      assert_equal [], result.reasoning
      assert_notify(
        notify_calls,
        stage: "preset:adult_content",
        openai_error_code: "invalid_image_url",
        text_length: "moderate me".length,
        image_url_count: 2,
        image_urls_sent: ["https://files.gumroad.com/bad.psd", "https://cdn.example.com/ok.png"]
      )
      assert_notify(notify_calls, stage: "preset:spam", image_urls_sent: [])
    end
  end

  test "skips the uncertainty flag and reports when the judge call is rejected" do
    call_count = 0
    client = FakeChatClient.new do
      call_count += 1
      case call_count
      when 1 then json_chat_response(flagged: true, reasoning: "looks explicit")
      when 2 then raise bad_request_error
      else json_chat_response(flagged: false, reasoning: "")
      end
    end

    with_strategy_stubs(client:) do |notify_calls:, **|
      result = Strategy.new(text: "moderate me").perform

      assert_equal "compliant", result.status
      assert_notify(notify_calls, stage: "uncertainty_check", openai_error_code: "invalid_image_url")
    end
  end

  test "filters out unsupported image formats before sending to OpenAI" do
    client = FakeChatClient.new(
      json_chat_response(flagged: false, reasoning: ""),
      json_chat_response(flagged: false, reasoning: "")
    )

    with_strategy_stubs(client:) do
      Strategy.new(
        text: "test",
        image_urls: ["https://cdn.example.com/photo.png", "https://cdn.example.com/design.psd", "https://cdn.example.com/logo.svg"]
      ).perform

      content = client.chat_parameters.first[:messages].last[:content]
      assert_includes content, { type: "image_url", image_url: { url: "https://cdn.example.com/photo.png" } }
      assert_not content.any? { _1.dig(:image_url, :url) == "https://cdn.example.com/design.psd" }
      assert_not content.any? { _1.dig(:image_url, :url) == "https://cdn.example.com/logo.svg" }
    end
  end

  test "evaluates text-only when all image URLs are unsupported" do
    client = FakeChatClient.new(
      json_chat_response(flagged: false, reasoning: ""),
      json_chat_response(flagged: false, reasoning: "")
    )

    with_strategy_stubs(client:) do |warnings:, **|
      result = Strategy.new(
        text: "test",
        image_urls: ["https://cdn.example.com/design.psd", "https://cdn.example.com/file.ai", "https://cdn.example.com/photo.tiff"]
      ).perform

      assert_equal "compliant", result.status
      assert warnings.any? { _1.match?(/filtered out all 3 image URLs \(unsupported formats\)/) }
    end
  end

  test "passes through supported formats normally" do
    client = FakeChatClient.new(
      json_chat_response(flagged: false, reasoning: ""),
      json_chat_response(flagged: false, reasoning: "")
    )

    with_strategy_stubs(client:) do
      Strategy.new(
        text: "test",
        image_urls: ["https://cdn.example.com/a.jpg", "https://cdn.example.com/b.jpeg", "https://cdn.example.com/c.gif", "https://cdn.example.com/d.webp"]
      ).perform

      assert_operator client.chat_parameters.size, :>=, 1
    end
  end

  test "returns compliant when a preset evaluation times out" do
    client = FakeChatClient.new(Faraday::TimeoutError.new("timeout"))

    with_strategy_stubs(client:) do |warnings:, **|
      result = Strategy.new(text: "moderate me", image_urls: ["https://cdn.example.com/1.png"]).perform

      assert_equal "compliant", result.status
      assert_equal [], result.reasoning
      assert warnings.any? { _1.match?(/preset timeout on adult_content.*Faraday::TimeoutError/) }
    end
  end

  test "returns compliant when a Net::ReadTimeout occurs" do
    client = FakeChatClient.new(Net::ReadTimeout.new("read timeout"))

    with_strategy_stubs(client:) do |warnings:, **|
      result = Strategy.new(text: "moderate me").perform

      assert_equal "compliant", result.status
      assert_equal [], result.reasoning
      assert warnings.any? { _1.match?(/preset timeout on adult_content.*Net::ReadTimeout/) }
    end
  end

  test "skips the flagged result when the uncertainty check times out" do
    call_count = 0
    client = FakeChatClient.new do
      call_count += 1
      case call_count
      when 1 then json_chat_response(flagged: true, reasoning: "looks explicit")
      when 2 then raise Faraday::TimeoutError, "timeout"
      else json_chat_response(flagged: false, reasoning: "")
      end
    end

    with_strategy_stubs(client:) do |warnings:, **|
      result = Strategy.new(text: "moderate me").perform

      assert_equal "compliant", result.status
      assert warnings.any? { _1.match?(/uncertainty check timeout.*Faraday::TimeoutError/) }
    end
  end

  test "returns compliant when a Faraday::ConnectionFailed occurs" do
    client = FakeChatClient.new(Faraday::ConnectionFailed.new("connection refused"))

    with_strategy_stubs(client:) do
      result = Strategy.new(text: "moderate me").perform

      assert_equal "compliant", result.status
      assert_equal [], result.reasoning
    end
  end

  test "returns compliant when OpenAI returns a server error" do
    client = FakeChatClient.new(Faraday::ServerError.new("the server responded with status 500"))

    with_strategy_stubs(client:) do |warnings:, **|
      result = Strategy.new(text: "moderate me").perform

      assert_equal "compliant", result.status
      assert_equal [], result.reasoning
      assert warnings.any? { _1.match?(/preset timeout on adult_content.*Faraday::ServerError/) }
    end
  end

  test "skips the flagged result when the uncertainty check gets a server error" do
    call_count = 0
    client = FakeChatClient.new do
      call_count += 1
      case call_count
      when 1 then json_chat_response(flagged: true, reasoning: "looks explicit")
      when 2 then raise Faraday::ServerError, "the server responded with status 500"
      else json_chat_response(flagged: false, reasoning: "")
      end
    end

    with_strategy_stubs(client:) do |warnings:, **|
      result = Strategy.new(text: "moderate me").perform

      assert_equal "compliant", result.status
      assert warnings.any? { _1.match?(/uncertainty check timeout.*Faraday::ServerError/) }
    end
  end

  test "SPAM_RULES tells the model that affiliate recruitment emails are legitimate" do
    assert_includes Strategy::SPAM_RULES, "affiliate recruitment email"
    assert_includes Strategy::SPAM_RULES, "earn a commission"
    assert_includes Strategy::SPAM_RULES, "MLM red flags"
  end

  private
    class FakeChatClient
      attr_reader :chat_parameters

      def initialize(*responses, &handler)
        @responses = responses
        @handler = handler
        @chat_parameters = []
      end

      def chat(parameters:)
        @chat_parameters << parameters
        response = @handler ? @handler.call(parameters) : (@responses.one? ? @responses.first : @responses.shift)
        raise response if response.is_a?(Exception)

        response
      end
    end

    def with_strategy_stubs(client:, openai_access_token: "test-key")
      openai_calls = []
      errors = []
      warnings = []
      notify_calls = []

      with_global_config("OPENAI_ACCESS_TOKEN" => openai_access_token) do
        OpenAI::Client.stub(:new, ->(**kwargs) { openai_calls << kwargs; client }) do
          Rails.logger.stub(:error, ->(message) { errors << message }) do
            Rails.logger.stub(:warn, ->(message) { warnings << message }) do
              ErrorNotifier.stub(:notify, ->(*args, **kwargs) { notify_calls << [args, kwargs] }) do
                yield(openai_calls:, errors:, warnings:, notify_calls:)
              end
            end
          end
        end
      end
    end

    def with_global_config(overrides, &block)
      original_get = GlobalConfig.method(:get)
      GlobalConfig.stub(:get, ->(key) { overrides.key?(key) ? overrides.fetch(key) : original_get.call(key) }, &block)
    end

    def json_chat_response(payload)
      { "choices" => [{ "message" => { "content" => payload.to_json } }] }
    end

    def bad_request_error
      response = {
        status: 400,
        body: {
          "error" => {
            "message" => "Error while downloading https://files.gumroad.com/bad.psd.",
            "type" => "invalid_request_error",
            "param" => nil,
            "code" => "invalid_image_url",
          },
        },
      }
      Faraday::BadRequestError.new("bad request", response)
    end

    def assert_notify(notify_calls, expected)
      assert(
        notify_calls.any? do |args, kwargs|
          args == ["ContentModeration::PromptStrategy OpenAI rejected input"] &&
            expected.all? { |key, value| kwargs[key] == value }
        end,
        "Expected ErrorNotifier.notify with #{expected.inspect}, got #{notify_calls.inspect}"
      )
    end
end
