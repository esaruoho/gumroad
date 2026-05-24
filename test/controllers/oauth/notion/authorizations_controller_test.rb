# frozen_string_literal: true

require "test_helper"

class Oauth::Notion::AuthorizationsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @user = users(:named_seller)
    @oauth_application = oauth_applications(:notion_app_for_named_seller)
    sign_in @user
  end

  test "GET new retrieves Notion Bot token" do
    fake_api = Minitest::Mock.new
    fake_api.expect(:get_bot_token, nil) do |code:, user:|
      code == "03a0066c-f0cf-442c-bcd9-sample" && user == @user
    end
    NotionApi.stub(:new, fake_api) do
      get :new, params: {
        client_id: @oauth_application.uid,
        response_type: "code",
        scope: "unfurl",
        code: "03a0066c-f0cf-442c-bcd9-sample",
        redirect_uri: "https://example.com"
      }
      assert_response :success
    end
    fake_api.verify
  end
end
