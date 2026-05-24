# frozen_string_literal: true

require "test_helper"

class Api::Internal::Installments::RecipientCountsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @seller = users(:named_seller)
    @seller.save! if @seller.external_id.blank?
    sign_in @seller
  end

  test "GET show requires authentication" do
    sign_out @seller
    get :show
    assert_includes [302, 401, 403], @response.status
  end
end
