# frozen_string_literal: true

require "test_helper"

class Helper::ClientTest < ActiveSupport::TestCase
  setup do
    @helper = Helper::Client.new
    @conversation_id = "123456"
  end

  # --- #create_hmac_digest ---
  test "create_hmac_digest creates a digest from url-encoded payload" do
    secret_key = "secret_key"
    GlobalConfig.stub(:get, ->(k) { k == "HELPER_WIDGET_SECRET" ? secret_key : nil }) do
      params = { key: "value", timestamp: DateTime.current.to_i }
      expected_digest = OpenSSL::HMAC.digest(OpenSSL::Digest.new("sha256"), secret_key, params.to_query)
      assert_equal expected_digest, @helper.create_hmac_digest(params:)
    end
  end

  test "create_hmac_digest creates a digest from JSON string" do
    secret_key = "secret_key"
    GlobalConfig.stub(:get, ->(k) { k == "HELPER_WIDGET_SECRET" ? secret_key : nil }) do
      json = { key: "value", timestamp: DateTime.current.to_i }
      expected_digest = OpenSSL::HMAC.digest(OpenSSL::Digest.new("sha256"), secret_key, json.to_json)
      assert_equal expected_digest, @helper.create_hmac_digest(json:)
    end
  end

  test "create_hmac_digest raises when both params and json provided" do
    params = { key: "value" }
    json = { another_key: "another_value" }
    err = assert_raises(RuntimeError) { @helper.create_hmac_digest(params:, json:) }
    assert_equal "Either params or json must be provided, but not both", err.message
  end

  test "create_hmac_digest raises when neither params nor json provided" do
    err = assert_raises(RuntimeError) { @helper.create_hmac_digest }
    assert_equal "Either params or json must be provided, but not both", err.message
  end

  # --- #close_conversation ---
  test "close_conversation sends a PATCH request to close the conversation" do
    stub_request(:patch, "https://api.helper.ai/api/v1/mailboxes/gumroad/conversations/#{@conversation_id}/")
      .with(
        body: hash_including(status: "closed", timestamp: Integer),
        headers: { "Content-Type" => "application/json" }
      )
      .to_return(status: 200)

    assert_equal true, @helper.close_conversation(conversation_id: @conversation_id)
  end

  test "close_conversation notifies error tracker on failure" do
    stub_request(:patch, "https://api.helper.ai/api/v1/mailboxes/gumroad/conversations/#{@conversation_id}/")
      .to_return(status: 422)

    mock = Minitest::Mock.new
    mock.expect(:call, nil, ["Helper error: could not close conversation"], conversation_id: @conversation_id)
    ErrorNotifier.stub(:notify, mock) do
      assert_equal false, @helper.close_conversation(conversation_id: @conversation_id)
    end
    mock.verify
  end

  # --- #send_reply ---
  test "send_reply sends a POST request to send a reply" do
    stub_request(:post, "https://api.helper.ai/api/v1/mailboxes/gumroad/conversations/#{@conversation_id}/emails/")
      .to_return(status: 200)
    assert_equal true, @helper.send_reply(conversation_id: @conversation_id, message: "Test reply message")
  end

  test "send_reply sends a POST request to send a draft" do
    message = "Test reply message"
    stub_request(:post, "https://api.helper.ai/api/v1/mailboxes/gumroad/conversations/#{@conversation_id}/emails/")
      .with(body: hash_including(message:, draft: true, timestamp: Integer))
      .to_return(status: 200)
    assert_equal true, @helper.send_reply(conversation_id: @conversation_id, message:, draft: true)
  end

  test "send_reply handles optional response_to" do
    response_to = "previous_message_id"
    stub_request(:post, "https://api.helper.ai/api/v1/mailboxes/gumroad/conversations/#{@conversation_id}/emails/")
      .with(body: hash_including(response_to:, timestamp: Integer))
      .to_return(status: 200)
    assert_equal true, @helper.send_reply(conversation_id: @conversation_id, message: "Test reply message", response_to:)
  end

  test "send_reply notifies error tracker on failure" do
    message = "Test reply message"
    stub_request(:post, "https://api.helper.ai/api/v1/mailboxes/gumroad/conversations/#{@conversation_id}/emails/")
      .to_return(status: 422)

    mock = Minitest::Mock.new
    mock.expect(:call, nil, ["Helper error: could not send reply"], conversation_id: @conversation_id, message: message)
    ErrorNotifier.stub(:notify, mock) do
      assert_equal false, @helper.send_reply(conversation_id: @conversation_id, message:)
    end
    mock.verify
  end

  # --- #add_note ---
  test "add_note sends a POST request to add a note" do
    message = "Test note message"
    stub_request(:post, "https://api.helper.ai/api/v1/mailboxes/gumroad/conversations/#{@conversation_id}/notes/")
      .with(body: hash_including(message: message, timestamp: Integer))
      .to_return(status: 200)
    assert_equal true, @helper.add_note(conversation_id: @conversation_id, message:)
  end

  test "add_note notifies error tracker on failure" do
    message = "Test note message"
    stub_request(:post, "https://api.helper.ai/api/v1/mailboxes/gumroad/conversations/#{@conversation_id}/notes/")
      .to_return(status: 422)

    mock = Minitest::Mock.new
    mock.expect(:call, nil, ["Helper error: could not add note"], conversation_id: @conversation_id, message: message)
    ErrorNotifier.stub(:notify, mock) do
      assert_equal false, @helper.add_note(conversation_id: @conversation_id, message:)
    end
    mock.verify
  end
end
