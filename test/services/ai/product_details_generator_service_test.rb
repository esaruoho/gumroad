# frozen_string_literal: true

require "test_helper"

class Ai::ProductDetailsGeneratorServiceTest < ActiveSupport::TestCase
  setup do
    @current_seller = users(:basic_user)
    @service = Ai::ProductDetailsGeneratorService.new(current_seller: @current_seller)
  end

  test "#generate_product_details generates product details successfully" do
    client = FakeOpenAIClient.new(chat_responses: [chat_response(product_details_payload)])

    with_openai_client(client) do
      result = @service.generate_product_details(prompt: "Create a coding tutorial ebook about Ruby on Rails for $29.99")

      assert_includes result.keys, :name
      assert_includes result.keys, :description
      assert_includes result.keys, :summary
      assert_includes result.keys, :native_type
      assert_includes result.keys, :number_of_content_pages
      assert_includes result.keys, :price
      assert_includes result.keys, :duration_in_seconds
      assert_equal "Ruby on Rails Coding Tutorial", result[:name]
      assert_equal "<p>Unlock the power of web development with Ruby on Rails.</p>", result[:description]
      assert_equal "A comprehensive ebook that teaches Ruby on Rails.", result[:summary]
      assert_equal "ebook", result[:native_type]
      assert_equal 4, result[:number_of_content_pages]
      assert_equal 29.99, result[:price]
      assert_nil result[:price_frequency_in_months]
      assert_equal "usd", result[:currency_code]
      assert_kind_of Numeric, result[:duration_in_seconds]
    end
  end

  test "#generate_product_details includes price frequency for membership products" do
    client = FakeOpenAIClient.new(chat_responses: [chat_response(product_details_payload(native_type: "membership", price_frequency_in_months: 3))])

    with_openai_client(client) do
      result = @service.generate_product_details(prompt: "Create a quarterly membership for Ruby on Rails developers for $19/month")

      assert_equal 3, result[:price_frequency_in_months]
    end
  end

  test "#generate_product_details returns price in seller currency from the OpenAI response" do
    client = FakeOpenAIClient.new(chat_responses: [chat_response(product_details_payload(price: 19.99, currency_code: "jpy"))])

    with_openai_client(client) do
      result = @service.generate_product_details(prompt: "Create a coding tutorial ebook about Ruby on Rails for 19.99 yen")

      assert_equal 19.99, result[:price]
      assert_equal "jpy", result[:currency_code]
    end
  end

  test "#generate_product_details raises an error with blank prompt" do
    error = assert_raises(Ai::ProductDetailsGeneratorService::InvalidPromptError) do
      @service.generate_product_details(prompt: "")
    end

    assert_equal "Prompt cannot be blank", error.message
  end

  test "#generate_product_details raises an error and retries when OpenAI returns invalid JSON" do
    client = FakeOpenAIClient.new(chat_responses: [{ "choices" => [{ "message" => { "content" => "invalid json response" } }] }])

    with_openai_client(client) do
      @service.stub(:sleep, ->(_delay) { }) do
        assert_raises(Ai::ProductDetailsGeneratorService::MaxRetriesExceededError) do
          @service.generate_product_details(prompt: "Create a coding tutorial ebook about Ruby on Rails for $29.99")
        end
      end
    end

    assert_equal 2, client.chat_parameters.size
  end

  test "#generate_cover_image generates cover image successfully" do
    client = FakeOpenAIClient.new(image_responses: [{ "data" => [{ "b64_json" => Base64.strict_encode64("jpeg data") }] }])

    with_openai_client(client) do
      result = @service.generate_cover_image(product_name: "Joy of Programming in Ruby")

      assert_equal "jpeg data", result[:image_data]
      assert_kind_of Numeric, result[:duration_in_seconds]
    end
  end

  test "#generate_cover_image raises an error and retries when OpenAI image generation fails" do
    client = FakeOpenAIClient.new(image_responses: [{ "data" => [] }])

    with_openai_client(client) do
      @service.stub(:sleep, ->(_delay) { }) do
        assert_raises(Ai::ProductDetailsGeneratorService::MaxRetriesExceededError) do
          @service.generate_cover_image(product_name: "Joy of Programming in Ruby")
        end
      end
    end

    assert_equal 2, client.image_parameters.size
  end

  test "#generate_rich_content_pages generates rich content pages successfully" do
    client = FakeOpenAIClient.new(chat_responses: [chat_response(rich_content_pages_payload)])

    with_openai_client(client) do
      result = @service.generate_rich_content_pages(product_info)

      assert_equal 2, result[:pages].size
      assert_equal "Introduction to Ruby", result[:pages].first["title"]
      assert_equal [
        { "type" => "heading", "attrs" => { "level" => 2 }, "content" => [{ "type" => "text", "text" => "What is Ruby?" }] },
        { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Ruby is a dynamic programming language." }] },
      ], result[:pages].first["content"]
      assert_equal "Getting Started with Ruby", result[:pages].last["title"]
      assert_equal [
        { "type" => "heading", "attrs" => { "level" => 2 }, "content" => [{ "type" => "text", "text" => "Setting Up Your Environment" }] },
        { "type" => "codeBlock", "content" => [{ "type" => "text", "text" => "puts 'Hello, World!'" }] },
      ], result[:pages].last["content"]
      assert_kind_of Numeric, result[:duration_in_seconds]
    end
  end

  test "#generate_rich_content_pages cleans malformed type colon syntax and parses successfully" do
    malformed_response = {
      "pages" => [
        {
          "title" => "Chapter 1",
          "content" => [
            { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Content" }] },
          ],
        },
      ],
    }
    client = FakeOpenAIClient.new(chat_responses: [chat_response(JSON.generate(malformed_response).gsub('"type"', '"type: "'), raw: true)])

    with_openai_client(client) do
      result = @service.generate_rich_content_pages(product_info)

      assert_kind_of Array, result[:pages]
      assert_equal "paragraph", result[:pages].first["content"].first["type"]
    end
  end

  private
    class FakeOpenAIClient
      attr_reader :chat_parameters, :image_parameters

      def initialize(chat_responses: [], image_responses: [])
        @chat_responses = chat_responses
        @image_responses = image_responses
        @chat_parameters = []
        @image_parameters = []
      end

      def chat(parameters:)
        @chat_parameters << parameters
        @chat_responses.one? ? @chat_responses.first : @chat_responses.shift
      end

      def images
        self
      end

      def generate(parameters:)
        @image_parameters << parameters
        @image_responses.one? ? @image_responses.first : @image_responses.shift
      end
    end

    def with_openai_client(client, &block)
      OpenAI::Client.stub(:new, ->(**_kwargs) { client }, &block)
    end

    def chat_response(payload, raw: false)
      content = raw ? payload : payload.to_json
      { "choices" => [{ "message" => { "content" => content } }] }
    end

    def product_details_payload(overrides = {})
      {
        name: "Ruby on Rails Coding Tutorial",
        description: "<p>Unlock the power of web development with Ruby on Rails.</p>",
        summary: "A comprehensive ebook that teaches Ruby on Rails.",
        native_type: "ebook",
        number_of_content_pages: 4,
        price: 29.99,
        currency_code: "usd",
        price_frequency_in_months: nil,
      }.merge(overrides)
    end

    def product_info
      {
        name: "Joy of Programming in Ruby",
        description: "<p>Learn Ruby from the ground up</p>",
        native_type: "ebook",
        number_of_content_pages: 2,
      }
    end

    def rich_content_pages_payload
      {
        "pages" => [
          {
            "title" => "Introduction to Ruby",
            "content" => [
              { "type" => "heading", "attrs" => { "level" => 2 }, "content" => [{ "type" => "text", "text" => "What is Ruby?" }] },
              { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Ruby is a dynamic programming language." }] },
            ],
          },
          {
            "title" => "Getting Started with Ruby",
            "content" => [
              { "type" => "heading", "attrs" => { "level" => 2 }, "content" => [{ "type" => "text", "text" => "Setting Up Your Environment" }] },
              { "type" => "codeBlock", "content" => [{ "type" => "text", "text" => "puts 'Hello, World!'" }] },
            ],
          },
        ],
      }
    end
end
