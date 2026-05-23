# frozen_string_literal: true

require "test_helper"

class PaypalIntegrationRestApiTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    @creator = users(:basic_user)
    @creator.update_column(:external_id, "ext123") if @creator.external_id.blank?
  end

  test "create_partner_referral succeeds and returns links in the response" do
    stub_request(:post, "#{PAYPAL_REST_ENDPOINT}/v2/customer/partner-referrals")
      .to_return(status: 201,
                 body: { links: [{ href: "https://x", rel: "self" }, { href: "https://y", rel: "action_url" }] }.to_json,
                 headers: { "Content-Type" => "application/json" })

    api_object = PaypalIntegrationRestApi.new(@creator, authorization_header: "Bearer test-token")
    response = api_object.create_partner_referral("http://example.com")

    assert response.success?
    assert_equal 2, response.parsed_response["links"].count
  end

  test "create_partner_referral with invalid header fails and returns 401" do
    stub_request(:post, "#{PAYPAL_REST_ENDPOINT}/v2/customer/partner-referrals")
      .to_return(status: 401, body: "Unauthorized")

    api_object = PaypalIntegrationRestApi.new(@creator, authorization_header: "invalid header")
    response = api_object.create_partner_referral("http://example.com")

    refute response.success?
    assert_equal 401, response.code
  end
end
