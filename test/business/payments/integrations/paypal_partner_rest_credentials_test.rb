# frozen_string_literal: true

require "test_helper"

class PaypalPartnerRestCredentialsTest < ActiveSupport::TestCase
  test "auth_token returns the cached token when present" do
    instance = PaypalPartnerRestCredentials.new
    instance.define_singleton_method(:load_token) { "random token" }
    instance.define_singleton_method(:request_for_api_token) { raise "should not be called" }
    assert_equal "random token", instance.auth_token
  end

  test "auth_token initiates an API call and returns a valid header value when cache is empty" do
    instance = PaypalPartnerRestCredentials.new
    instance.define_singleton_method(:load_token) { nil }
    fake_response = { "token_type" => "Bearer", "access_token" => "abc123", "expires_in" => "3600" }
    PaypalPartnerRestCredentials.stub :post, fake_response do
      auth_token = instance.auth_token
      assert_kind_of String, auth_token
      assert_match(/^[^\s]+ [^\s]+$/, auth_token)
    end
  end

  test "auth_token raises an exception on API call failure" do
    instance = PaypalPartnerRestCredentials.new
    instance.define_singleton_method(:load_token) { nil }
    instance.define_singleton_method(:sleep) { |_| nil }
    PaypalPartnerRestCredentials.stub :post, ->(*_args, **_kwargs) { raise SocketError } do
      assert_raises(SocketError) { instance.auth_token }
    end
  end
end
