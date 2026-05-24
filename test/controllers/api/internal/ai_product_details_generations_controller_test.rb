# frozen_string_literal: true

require "test_helper"

class Api::Internal::AiProductDetailsGenerationsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test "POST create redirects unauthenticated users to login" do
    post :create, params: { prompt: "anything" }
    assert_response :redirect
    assert_match %r{/login}, response.location
  end

  test "POST create with no params still redirects unauthenticated users" do
    post :create
    assert_response :redirect
    assert_match %r{/login}, response.location
  end
end
