# frozen_string_literal: true

require "test_helper"

class ContentModeration::Strategies::ClassifierStrategyTest < ActiveSupport::TestCase
  Strategy = ContentModeration::Strategies::ClassifierStrategy
  DEFAULT_TEXT = "text to moderate"
  DEFAULT_IMAGE_URLS = ["https://cdn.example.com/1.png"].freeze

  test "returns compliant when the API key is blank" do
    client = FakeModerationsClient.new

    with_strategy_stubs(client:, openai_access_token: nil) do |openai_calls:, **|
      result = Strategy.new(text: DEFAULT_TEXT, image_urls: DEFAULT_IMAGE_URLS).perform

      assert_equal "compliant", result.status
      assert_empty openai_calls
    end
  end

  test "returns compliant when both text and images are empty" do
    client = FakeModerationsClient.new

    with_strategy_stubs(client:) do |openai_calls:, **|
      result = Strategy.new(text: "", image_urls: []).perform

      assert_equal "compliant", result.status
      assert_empty openai_calls
    end
  end

  test "flags content when a category score exceeds the threshold" do
    client = FakeModerationsClient.new(moderation_response("sexual" => 0.91))

    with_strategy_stubs(client:) do
      result = Strategy.new(text: DEFAULT_TEXT, image_urls: DEFAULT_IMAGE_URLS).perform

      assert_equal "flagged", result.status
      assert_equal ["OpenAI moderation flagged: sexual (score: 0.91, threshold: 0.8)"], result.reasoning
    end
  end

  test "respects custom thresholds from GlobalConfig" do
    client = FakeModerationsClient.new(moderation_response("sexual" => 0.91))

    with_strategy_stubs(client:, classifier_thresholds: '{"sexual":0.95}') do
      result = Strategy.new(text: DEFAULT_TEXT, image_urls: DEFAULT_IMAGE_URLS).perform

      assert_equal "compliant", result.status
      assert_equal [], result.reasoning
    end
  end

  test "sends one image per moderation request" do
    image_urls = [
      "https://cdn.example.com/1.png",
      "https://cdn.example.com/2.png",
      "https://cdn.example.com/3.png",
    ]
    client = FakeModerationsClient.new { moderation_response({}) }

    with_strategy_stubs(client:) do
      Strategy.new(text: DEFAULT_TEXT, image_urls:).perform

      client.inputs.each do |input|
        assert_operator input.count { _1[:type] == "image_url" }, :<=, 1
      end
    end
  end

  test "moderates text and every image up to the cap in separate requests" do
    image_urls = 7.times.map { |i| "https://cdn.example.com/#{i}.png" }
    client = FakeModerationsClient.new { moderation_response({}) }

    with_strategy_stubs(client:) do
      Strategy.new(text: DEFAULT_TEXT, image_urls:).perform

      assert_equal 1 + Strategy::MAX_IMAGES_TO_MODERATE, client.inputs.size
      assert_equal [{ type: "text", text: DEFAULT_TEXT }], client.inputs.first

      image_calls = client.inputs.drop(1)
      assert image_calls.all? { |input| input.size == 1 && input.first[:type] == "image_url" }
      tested_urls = image_calls.map { _1.first[:image_url][:url] }
      assert tested_urls.all? { image_urls.include?(_1) }
      assert_equal Strategy::MAX_IMAGES_TO_MODERATE, tested_urls.uniq.size
    end
  end

  test "skips image URLs rejected as bad requests and continues with remaining images" do
    image_urls = [
      "blob:https://gumroad.com/bad-1",
      "https://cdn.example.com/good-1.png",
      "https://cdn.example.com/good-2.png",
    ]
    client = FakeModerationsClient.new do |parameters|
      part = parameters[:input].first
      raise bad_request_error if part[:type] == "image_url" && part[:image_url][:url].start_with?("blob:")

      moderation_response({})
    end

    with_strategy_stubs(client:) do |warnings:, **|
      result = Strategy.new(text: "", image_urls:).perform

      assert_equal "compliant", result.status
      assert_equal 3, client.inputs.size
      assert_equal 1, warnings.count { _1.match?(/skipping unmoderatable image URL=blob:https:\/\/gumroad\.com\/bad-1/) }
    end
  end

  test "still flags content based on successful image moderations after skipping a bad URL" do
    image_urls = ["blob:https://gumroad.com/bad", "https://cdn.example.com/good.png"]
    client = FakeModerationsClient.new do |parameters|
      part = parameters[:input].first
      raise bad_request_error if part[:type] == "image_url" && part[:image_url][:url].start_with?("blob:")

      moderation_response("violence" => 0.95)
    end

    with_strategy_stubs(client:) do
      result = Strategy.new(text: "", image_urls:).perform

      assert_equal "flagged", result.status
      assert_equal ["OpenAI moderation flagged: violence (score: 0.95, threshold: 0.8)"], result.reasoning
    end
  end

  test "returns flagged with retry reason when every image URL fails and there is no text" do
    image_urls = [
      "blob:https://gumroad.com/bad-1",
      "https://cdn.example.com/bad-2.png",
      "https://cdn.example.com/bad-3.png",
    ]
    client = FakeModerationsClient.new { raise bad_request_error }

    with_strategy_stubs(client:) do |notify_calls:, **|
      result = Strategy.new(text: "", image_urls:).perform

      assert_equal "flagged", result.status
      assert_equal [Strategy::UNAVAILABLE_REASON], result.reasoning
      assert_notify(notify_calls, "ContentModeration::ClassifierStrategy could not moderate any image",
                    image_url_count: 3, skipped_urls: image_urls)
    end
  end

  test "returns compliant and notifies when every image fails but text was moderated successfully" do
    image_urls = ["https://cdn.example.com/bad-1.png", "https://cdn.example.com/bad-2.png"]
    client = FakeModerationsClient.new do |parameters|
      part = parameters[:input].first
      raise Faraday::ServerError, "500 Internal Server Error" if part[:type] == "image_url"

      moderation_response({})
    end

    with_strategy_stubs(client:) do |notify_calls:, **|
      result = Strategy.new(text: "some clean text", image_urls:).perform

      assert_equal "compliant", result.status
      assert_equal [], result.reasoning
      assert_notify(notify_calls, "ContentModeration::ClassifierStrategy could not moderate any image",
                    image_url_count: 2, skipped_urls: image_urls)
    end
  end

  test "still flags text categories when image moderation fails alongside successful text moderation" do
    client = FakeModerationsClient.new do |parameters|
      part = parameters[:input].first
      raise Faraday::ServerError, "500 Internal Server Error" if part[:type] == "image_url"

      moderation_response("violence" => 0.95)
    end

    with_strategy_stubs(client:) do
      result = Strategy.new(text: "violent text", image_urls: ["https://cdn.example.com/bad.png"]).perform

      assert_equal "flagged", result.status
      assert_equal ["OpenAI moderation flagged: violence (score: 0.95, threshold: 0.8)"], result.reasoning
    end
  end

  test "does not flag image unavailability when text exists and image_urls is empty" do
    client = FakeModerationsClient.new(moderation_response({}))

    with_strategy_stubs(client:) do |notify_calls:, **|
      result = Strategy.new(text: "some text", image_urls: []).perform

      assert_equal "compliant", result.status
      assert_empty notify_calls
    end
  end

  test "logs and re-raises non-image OpenAI errors" do
    client = FakeModerationsClient.new(StandardError.new("API failure"))

    with_strategy_stubs(client:) do |errors:, **|
      error = assert_raises(StandardError) { Strategy.new(text: DEFAULT_TEXT, image_urls: DEFAULT_IMAGE_URLS).perform }

      assert_equal "API failure", error.message
      assert_includes errors, "ContentModeration::ClassifierStrategy error: API failure"
    end
  end

  test "retries on Faraday::TimeoutError and succeeds when a subsequent attempt returns" do
    client = client_that_succeeds_after(Faraday::TimeoutError.new("Net::ReadTimeout"), attempts: 3)

    with_strategy_stubs(client:) do |warnings:, **|
      result = Strategy.new(text: DEFAULT_TEXT, image_urls: []).perform

      assert_equal "compliant", result.status
      assert_equal 3, client.moderations_calls.size
      assert warnings.any? { _1.match?(/TimeoutError on attempt 1\/3, retrying/) }
      assert warnings.any? { _1.match?(/TimeoutError on attempt 2\/3, retrying/) }
    end
  end

  test "returns flagged with unavailable reason after max timeout attempts" do
    client = FakeModerationsClient.new { raise Faraday::TimeoutError, "Net::ReadTimeout" }

    with_strategy_stubs(client:) do |notify_calls:, **|
      result = Strategy.new(text: DEFAULT_TEXT, image_urls: []).perform

      assert_equal "flagged", result.status
      assert_equal [Strategy::UNAVAILABLE_REASON], result.reasoning
      assert_equal Strategy::MAX_MODERATION_ATTEMPTS, client.moderations_calls.size
      assert_exception_notify(notify_calls, Faraday::TimeoutError, input_type: "text", skip_url: nil)
    end
  end

  test "retries on Faraday::ParsingError and succeeds when a subsequent attempt returns valid JSON" do
    client = client_that_succeeds_after(Faraday::ParsingError.new("unexpected character"), attempts: 2)

    with_strategy_stubs(client:) do |warnings:, **|
      result = Strategy.new(text: DEFAULT_TEXT, image_urls: []).perform

      assert_equal "compliant", result.status
      assert_equal 2, client.moderations_calls.size
      assert warnings.any? { _1.match?(/ParsingError on attempt 1\/3, retrying/) }
    end
  end

  test "returns flagged with unavailable reason after max parsing errors" do
    client = FakeModerationsClient.new { raise Faraday::ParsingError, "unexpected character" }

    with_strategy_stubs(client:) do |notify_calls:, **|
      result = Strategy.new(text: DEFAULT_TEXT, image_urls: []).perform

      assert_equal "flagged", result.status
      assert_equal [Strategy::UNAVAILABLE_REASON], result.reasoning
      assert_equal Strategy::MAX_MODERATION_ATTEMPTS, client.moderations_calls.size
      assert_exception_notify(notify_calls, Faraday::ParsingError, input_type: "text", skip_url: nil)
    end
  end

  test "retries on Faraday::ConnectionFailed and succeeds when a subsequent attempt returns" do
    client = client_that_succeeds_after(Faraday::ConnectionFailed.new("Failed to open TCP connection"), attempts: 3)

    with_strategy_stubs(client:) do |warnings:, **|
      result = Strategy.new(text: DEFAULT_TEXT, image_urls: []).perform

      assert_equal "compliant", result.status
      assert_equal 3, client.moderations_calls.size
      assert warnings.any? { _1.match?(/ConnectionFailed on attempt 1\/3, retrying/) }
      assert warnings.any? { _1.match?(/ConnectionFailed on attempt 2\/3, retrying/) }
    end
  end

  test "returns flagged with unavailable reason after max connection failures" do
    client = FakeModerationsClient.new { raise Faraday::ConnectionFailed, "Failed to open TCP connection" }

    with_strategy_stubs(client:) do |notify_calls:, **|
      result = Strategy.new(text: DEFAULT_TEXT, image_urls: []).perform

      assert_equal "flagged", result.status
      assert_equal [Strategy::UNAVAILABLE_REASON], result.reasoning
      assert_equal Strategy::MAX_MODERATION_ATTEMPTS, client.moderations_calls.size
      assert_exception_notify(notify_calls, Faraday::ConnectionFailed, input_type: "text", skip_url: nil)
    end
  end

  test "retries on Faraday::ServerError and succeeds when a subsequent attempt returns" do
    client = client_that_succeeds_after(Faraday::ServerError.new("500 Internal Server Error"), attempts: 3)

    with_strategy_stubs(client:) do |warnings:, **|
      result = Strategy.new(text: DEFAULT_TEXT, image_urls: []).perform

      assert_equal "compliant", result.status
      assert_equal 3, client.moderations_calls.size
      assert warnings.any? { _1.match?(/ServerError on attempt 1\/3, retrying/) }
      assert warnings.any? { _1.match?(/ServerError on attempt 2\/3, retrying/) }
    end
  end

  test "returns flagged with unavailable reason after max server errors" do
    client = FakeModerationsClient.new { raise Faraday::ServerError, "500 Internal Server Error" }

    with_strategy_stubs(client:) do |notify_calls:, **|
      result = Strategy.new(text: DEFAULT_TEXT, image_urls: []).perform

      assert_equal "flagged", result.status
      assert_equal [Strategy::UNAVAILABLE_REASON], result.reasoning
      assert_equal Strategy::MAX_MODERATION_ATTEMPTS, client.moderations_calls.size
      assert_exception_notify(notify_calls, Faraday::ServerError, input_type: "text", skip_url: nil)
    end
  end

  private
    class FakeModerationsClient
      attr_reader :moderations_calls, :inputs

      def initialize(*responses, &handler)
        @responses = responses
        @handler = handler
        @moderations_calls = []
        @inputs = []
      end

      def moderations(parameters:)
        @moderations_calls << parameters
        @inputs << parameters[:input]
        response = @handler ? @handler.call(parameters) : (@responses.one? ? @responses.first : @responses.shift)
        raise response if response.is_a?(Exception)

        response
      end
    end

    def with_strategy_stubs(client:, openai_access_token: "test-key", classifier_thresholds: nil)
      openai_calls = []
      errors = []
      warnings = []
      notify_calls = []

      with_global_config(
        "OPENAI_ACCESS_TOKEN" => openai_access_token,
        "CONTENT_MODERATION_CLASSIFIER_THRESHOLDS" => classifier_thresholds
      ) do
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

    def moderation_response(scores)
      { "results" => [{ "category_scores" => scores }] }
    end

    def bad_request_error
      Faraday::BadRequestError.new("bad request", { status: 400, body: { "error" => { "code" => "image_url_unavailable" } } })
    end

    def client_that_succeeds_after(exception, attempts:)
      call_count = 0
      FakeModerationsClient.new do
        call_count += 1
        raise exception if call_count < attempts

        moderation_response({})
      end
    end

    def assert_notify(notify_calls, message, expected)
      assert(
        notify_calls.any? do |args, kwargs|
          args == [message] &&
            expected.all? do |key, value|
              key == :skipped_urls ? kwargs[key].sort == value.sort : kwargs[key] == value
            end
        end,
        "Expected ErrorNotifier.notify with #{message.inspect} and #{expected.inspect}, got #{notify_calls.inspect}"
      )
    end

    def assert_exception_notify(notify_calls, exception_class, expected)
      assert(
        notify_calls.any? do |args, kwargs|
          args.first.is_a?(exception_class) &&
            kwargs[:attempts] == Strategy::MAX_MODERATION_ATTEMPTS &&
            expected.all? { |key, value| kwargs[key] == value }
        end,
        "Expected ErrorNotifier.notify with #{exception_class}, got #{notify_calls.inspect}"
      )
    end
end
