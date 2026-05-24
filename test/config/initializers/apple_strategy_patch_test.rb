# frozen_string_literal: true

require "test_helper"

class AppleStrategyPatchTest < ActiveSupport::TestCase
  def strategy
    @strategy ||= OmniAuth::Strategies::Apple.new(Rails.application, "client_id", "")
  end

  def sign_cookie(data)
    Rails.application.message_verifier("apple_oauth").generate(
      data, purpose: :apple_oauth, expires_in: APPLE_OAUTH_COOKIE_TTL
    )
  end

  def build_env(path, method: "POST", input: nil, cookies: nil)
    opts = { method: method }
    opts[:input] = input if input
    opts["HTTP_COOKIE"] = cookies if cookies

    env = Rack::MockRequest.env_for(path, **opts)
    env["rack.session"] = {}
    env
  end

  def prepare_strategy(env)
    strategy.instance_variable_set(:@env, env)
    strategy.instance_variable_set(:@cookie_data, nil)
    strategy.instance_variable_set(:@user_info, nil)
  end

  # #stored_nonce

  test "#stored_nonce reads the nonce from the signed cookie" do
    nonce = SecureRandom.urlsafe_base64(32)
    cookie_value = sign_cookie({ "nonce" => nonce, "referer" => "/library" })

    env = build_env(
      "/users/auth/apple/callback",
      cookies: "#{APPLE_OAUTH_COOKIE_NAME}=#{Rack::Utils.escape(cookie_value)}"
    )
    prepare_strategy(env)

    assert_equal nonce, strategy.send(:stored_nonce)
  end

  test "#stored_nonce returns nil when cookie is missing" do
    env = build_env("/users/auth/apple/callback")
    prepare_strategy(env)

    assert_nil strategy.send(:stored_nonce)
  end

  test "#stored_nonce returns nil when cookie has been tampered with" do
    env = build_env(
      "/users/auth/apple/callback",
      cookies: "#{APPLE_OAUTH_COOKIE_NAME}=tampered-value"
    )
    prepare_strategy(env)

    assert_nil strategy.send(:stored_nonce)
  end

  # #callback_phase

  test "#callback_phase restores omniauth.params from cookie data without the nonce" do
    nonce = SecureRandom.urlsafe_base64(32)
    cookie_value = sign_cookie({ "nonce" => nonce, "referer" => "/library" })

    env = build_env(
      "/users/auth/apple/callback",
      cookies: "#{APPLE_OAUTH_COOKIE_NAME}=#{Rack::Utils.escape(cookie_value)}"
    )
    prepare_strategy(env)

    begin
      strategy.callback_phase
    rescue
      # callback_phase calls super which fails without a real Apple id_token
    end

    assert_equal({ "referer" => "/library" }, env["omniauth.params"])
  end

  test "#callback_phase parses JSON user param into a hash" do
    user_json = '{"name":{"firstName":"Jane","lastName":"Appleseed"},"email":"jane@example.com"}'
    cookie_value = sign_cookie({ "nonce" => "test" })

    env = build_env(
      "/users/auth/apple/callback",
      input: "user=#{Rack::Utils.escape(user_json)}",
      cookies: "#{APPLE_OAUTH_COOKIE_NAME}=#{Rack::Utils.escape(cookie_value)}"
    )
    Rack::Request.new(env).POST
    prepare_strategy(env)

    begin
      strategy.callback_phase
    rescue
    end

    assert_kind_of Hash, env["rack.request.form_hash"]["user"]
    assert_equal "jane@example.com", env["rack.request.form_hash"]["user"]["email"]
  end

  test "#callback_phase leaves non-JSON user param as-is" do
    cookie_value = sign_cookie({ "nonce" => "test" })

    env = build_env(
      "/users/auth/apple/callback",
      input: "user=not-json",
      cookies: "#{APPLE_OAUTH_COOKIE_NAME}=#{Rack::Utils.escape(cookie_value)}"
    )
    Rack::Request.new(env).POST
    prepare_strategy(env)

    begin
      strategy.callback_phase
    rescue
    end

    assert_equal "not-json", env["rack.request.form_hash"]["user"]
  end

  # #request_phase

  test "#request_phase sets a signed SameSite=None cookie with nonce and referer" do
    mock_client = OAuth2::Client.new("client_id", "fake_secret", site: "https://appleid.apple.com", authorize_url: "/auth/authorize", token_url: "/auth/token")
    strategy.stub(:client, mock_client) do
      env = build_env("/users/auth/apple?referer=/library", method: "GET")
      prepare_strategy(env)

      result = strategy.request_phase

      cookie_header = result[1]["set-cookie"] || result[1]["Set-Cookie"]
      assert cookie_header.present?
      assert_includes cookie_header, APPLE_OAUTH_COOKIE_NAME
      assert_includes cookie_header.downcase, "samesite=none"
      assert_includes cookie_header.downcase, "httponly"

      cookie_value = cookie_header.match(/#{APPLE_OAUTH_COOKIE_NAME}=([^;]+)/o)[1]
      decoded = Rails.application.message_verifier("apple_oauth").verified(
        Rack::Utils.unescape(cookie_value), purpose: :apple_oauth
      )
      assert decoded["nonce"].present?
      assert_equal "/library", decoded["referer"]
    end
  end

  test "#request_phase omits referer from cookie when not provided" do
    mock_client = OAuth2::Client.new("client_id", "fake_secret", site: "https://appleid.apple.com", authorize_url: "/auth/authorize", token_url: "/auth/token")
    strategy.stub(:client, mock_client) do
      env = build_env("/users/auth/apple", method: "GET")
      prepare_strategy(env)

      result = strategy.request_phase

      cookie_header = result[1]["set-cookie"] || result[1]["Set-Cookie"]
      cookie_value = cookie_header.match(/#{APPLE_OAUTH_COOKIE_NAME}=([^;]+)/o)[1]
      decoded = Rails.application.message_verifier("apple_oauth").verified(
        Rack::Utils.unescape(cookie_value), purpose: :apple_oauth
      )
      refute decoded.key?("referer")
    end
  end

  # #authorize_params

  test "#authorize_params includes a nonce parameter" do
    env = build_env("/users/auth/apple", method: "GET")
    prepare_strategy(env)

    params = strategy.authorize_params
    assert params[:nonce].present?
    assert params[:nonce].length >= 32
  end

  test "#authorize_params generates a unique nonce each time" do
    env = build_env("/users/auth/apple", method: "GET")
    prepare_strategy(env)

    nonce1 = strategy.authorize_params[:nonce]

    strategy.instance_variable_set(:@apple_oauth_nonce, nil)
    nonce2 = strategy.authorize_params[:nonce]

    refute_equal nonce1, nonce2
  end

  # #user_info

  test "#user_info returns hash user data as-is from form-encoded request params" do
    env = build_env(
      "/users/auth/apple/callback",
      input: "user%5BfirstName%5D=Jane&user%5BlastName%5D=Doe"
    )
    Rack::Request.new(env).POST
    prepare_strategy(env)

    info = strategy.send(:user_info)
    assert_kind_of Hash, info
    assert_equal "Jane", info["firstName"]
  end

  test "#user_info parses a JSON string user param without callback_phase form_hash rewrite" do
    user_json = '{"name":{"firstName":"Jane","lastName":"Appleseed"},"email":"jane@example.com"}'
    env = build_env(
      "/users/auth/apple/callback",
      input: "user=#{Rack::Utils.escape(user_json)}"
    )
    Rack::Request.new(env).POST
    prepare_strategy(env)

    info = strategy.send(:user_info)
    assert_kind_of Hash, info
    assert_equal "jane@example.com", info["email"]
    assert_equal "Jane", info.dig("name", "firstName")
  end

  test "#user_info returns empty hash when no user data is present" do
    env = build_env("/users/auth/apple/callback")
    prepare_strategy(env)

    assert_equal({}, strategy.send(:user_info))
  end
end
