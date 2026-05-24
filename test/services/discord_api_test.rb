# frozen_string_literal: true

require "test_helper"

class DiscordApiTest < ActiveSupport::TestCase
  test "POST oauth_token makes an oauth authorization request with the given code and redirect uri" do
    WebMock.stub_request(:post, DISCORD_OAUTH_TOKEN_URL)
      .with(
        body: {
          grant_type: "authorization_code",
          code: "test_code",
          client_id: DISCORD_CLIENT_ID,
          client_secret: DISCORD_CLIENT_SECRET,
          redirect_uri: "test_uri"
        },
        headers: { "Content-Type" => "application/x-www-form-urlencoded" }
      )

    response = DiscordApi.new.oauth_token("test_code", "test_uri")
    assert_equal true, response.success?
  end
end
