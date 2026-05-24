# frozen_string_literal: true

require "test_helper"

class PaypalControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "POST billing_agreement_token returns generated token id" do
    PaypalChargeProcessor.stub(:generate_billing_agreement_token, ->(_) { "BA-TOKEN-1" }) do
      post :billing_agreement_token, params: { shipping: "true" }
    end
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal "BA-TOKEN-1", body["billing_agreement_token_id"]
  end

  test "POST billing_agreement_token swallows ChargeProcessorError and returns nil id" do
    PaypalChargeProcessor.stub(:generate_billing_agreement_token, ->(_) { raise ChargeProcessorError, "boom" }) do
      post :billing_agreement_token, params: { shipping: "false" }
    end
    assert_response :success
    body = JSON.parse(@response.body)
    assert_nil body["billing_agreement_token_id"]
  end
end
