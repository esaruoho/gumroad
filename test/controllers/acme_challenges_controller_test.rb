# frozen_string_literal: true

require "test_helper"

class AcmeChallengesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  setup do
    @token = "a" * 43
    @challenge_content = "challenge-response-content"
  end

  test "returns the challenge content when challenge exists in Redis" do
    $redis.set(RedisKey.acme_challenge(@token), @challenge_content)
    begin
      get :show, params: { token: @token }
      assert_response :success
      assert_equal @challenge_content, @response.body
    ensure
      $redis.del(RedisKey.acme_challenge(@token))
    end
  end

  test "returns not found when challenge does not exist in Redis" do
    get :show, params: { token: @token }
    assert_response :not_found
  end

  test "returns bad request when token is too long" do
    get :show, params: { token: "a" * 65 }
    assert_response :bad_request
  end

  test "returns bad request when token contains invalid characters" do
    get :show, params: { token: "invalid!token@chars" }
    assert_response :bad_request
  end
end
