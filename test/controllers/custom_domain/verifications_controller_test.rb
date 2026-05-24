# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class CustomDomain::VerificationsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @admin = users(:admin_for_named_seller)
    [@seller, @admin].each { |u| u.save(validate: false) if u.external_id.blank? }
    sign_in_as_seller(@admin, @seller)
  end

  teardown do
    restore_protect_against_forgery!
    CustomDomainVerificationService.send(:remove_method, :process) if CustomDomainVerificationService.instance_methods(false).include?(:process)
  end

  def stub_service_result(result)
    CustomDomainVerificationService.define_method(:process) { result }
  end

  test "POST create returns false when a blank domain is specified" do
    stub_service_result(false)
    post :create, params: { domain: "" }, format: :json
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal false, body["success"]
  end

  test "POST create returns success when the domain is correctly configured" do
    stub_service_result(true)
    post :create, params: { domain: "product.example.com" }, format: :json
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal true, body["success"]
    assert_equal "product.example.com domain is correctly configured!", body["message"]
  end

  test "POST create with product_id returns success when domain is configured for the product" do
    stub_service_result(true)
    product = links(:basic_user_product)
    post :create, params: { domain: "product.example.com", product_id: product.external_id }, format: :json
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal true, body["success"]
  end

  test "POST create with product_id rejects when domain belongs to another product" do
    stub_service_result(true)
    product = links(:basic_user_product)
    other = links(:named_seller_product)
    CustomDomain.create!(domain: "product.example.com", user: nil, product: other)

    post :create, params: { domain: "product.example.com", product_id: product.external_id }, format: :json
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal false, body["success"]
    # Either the model validation message or fallback
    assert body["message"].present?
  end

  test "POST create returns failure when the specified domain is not configured" do
    stub_service_result(false)
    post :create, params: { domain: "store.example.com" }, format: :json
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal false, body["success"]
    assert_equal "Domain verification failed. Please make sure you have correctly configured the DNS record for store.example.com.", body["message"]
  end
end
