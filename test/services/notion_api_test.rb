# frozen_string_literal: true

require "test_helper"

class NotionApiTest < ActiveSupport::TestCase
  test "#get_bot_token sends authorization code to Notion and returns parsed response" do
    user = users(:basic_user)
    user.update!(email: "user@example.com")
    user.save! if user.external_id.blank?

    GlobalConfig.singleton_class.send(:alias_method, :__orig_get_for_notion_test, :get)
    GlobalConfig.define_singleton_method(:get) do |key|
      case key
      when "NOTION_OAUTH_CLIENT_ID" then "id-1234"
      when "NOTION_OAUTH_CLIENT_SECRET" then "secret-1234"
      end
    end

    response_body = {
      "access_token" => "secret_cKEExFXDe4r0JxyDDwdqhO9rpMKJ_SAMPLE",
      "bot_id" => "e511ea88-8c43-410d-848f-0e2804aab14d",
      "token_type" => "bearer"
    }

    expected_auth = "Basic #{Base64.strict_encode64("id-1234:secret-1234")}"

    captured = {}
    stub = WebMock.stub_request(:post, "https://api.notion.com/v1/oauth/token")
                  .to_return(status: 200, body: response_body.to_json, headers: { "Content-Type" => "application/json" })

    begin
      result = NotionApi.new.get_bot_token(code: "03a0066c-f0cf-442c-bcd9-sample", user: user)

      assert_equal response_body, result.parsed_response
      assert_requested(:post, "https://api.notion.com/v1/oauth/token") do |req|
        captured[:body] = JSON.parse(req.body)
        captured[:auth] = req.headers["Authorization"]
        true
      end
      assert_equal "03a0066c-f0cf-442c-bcd9-sample", captured[:body]["code"]
      assert_equal "authorization_code", captured[:body]["grant_type"]
      assert_equal user.external_id, captured[:body].dig("external_account", "key")
      assert_equal user.email, captured[:body].dig("external_account", "name")
      assert_equal expected_auth, captured[:auth]
    ensure
      WebMock.remove_request_stub(stub)
      GlobalConfig.singleton_class.send(:remove_method, :get)
      GlobalConfig.singleton_class.send(:alias_method, :get, :__orig_get_for_notion_test)
      GlobalConfig.singleton_class.send(:remove_method, :__orig_get_for_notion_test)
    end
  end
end
