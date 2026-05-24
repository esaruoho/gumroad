# frozen_string_literal: true

require "test_helper"

class Api::Internal::Installments::AudienceCountsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @seller = users(:named_seller)
    @seller.save! if @seller.external_id.blank?
    sign_in @seller
    @installment = installments(:published_post)
  end

  test "GET show returns 404 when installment is missing" do
    get :show, params: { id: "missing-external-id" }
    assert_response :not_found
  end

  test "GET show requires authentication" do
    sign_out @seller
    get :show, params: { id: @installment.external_id }
    assert_includes [302, 401, 403], @response.status
  end
end
