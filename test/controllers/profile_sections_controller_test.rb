# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class ProfileSectionsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @seller.save(validate: false) if @seller.external_id.blank?
    sign_in_as_seller(@seller)
  end

  teardown { restore_protect_against_forgery! }

  test "POST create returns 422 with errors when type is missing" do
    post :create, params: { header: "Hi" }, as: :json
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert body.key?("error")
  end

  test "POST create returns 422 with invalid section type" do
    post :create, params: { type: "InvalidType", header: "Hi" }, as: :json
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal "Invalid section type", body["error"]
  end

  test "PATCH update returns 404 when section not found" do
    assert_raises(ActiveRecord::RecordNotFound) do
      patch :update, params: { id: "does-not-exist", header: "Hi" }, as: :json
    end
  end
end
