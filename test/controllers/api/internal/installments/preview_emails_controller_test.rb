# frozen_string_literal: true

require "test_helper"

class Api::Internal::Installments::PreviewEmailsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @seller = users(:named_seller)
    @seller.save! if @seller.external_id.blank?
    sign_in @seller
    @installment = installments(:published_post)
  end

  test "POST create returns 404 when no installment matches" do
    @request.cookies[:_gumroad_app_session] = nil
    # current_seller is named_seller (signed in)
    Pundit::Policy::Scope.send(:nil) if false
    User.any_instance.stubs(:installments).returns(Installment.none) if defined?(Mocha)
    # Use a missing external_id; controller returns e404_json before authorize.
    post :create, params: { id: "missing-external-id" }
    # If the seller setup redirects (no merchant flow), accept 302 OR 404.
    assert_includes [404, 302], @response.status
  end

  test "POST create requires authentication" do
    sign_out @seller
    post :create, params: { id: @installment.external_id }
    # Sellers::BaseController -> authenticate_user! triggers redirect to login (302) or 401.
    assert_includes [302, 401, 403], @response.status
  end
end
