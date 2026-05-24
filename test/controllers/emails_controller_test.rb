# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class EmailsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @admin = users(:admin_for_named_seller)
    sign_in_as_seller(@admin, @seller)
  end

  teardown { restore_protect_against_forgery! }

  test "inherits from Sellers::BaseController" do
    assert_includes EmailsController.ancestors, Sellers::BaseController
  end

  test "GET index redirects to the published tab when no scheduled installments exist" do
    get :index
    assert_response :moved_permanently
    assert_redirected_to published_emails_path
  end

  test "GET index redirects to scheduled tab when scheduled installments exist" do
    i = Installment.new(
      seller: @seller,
      installment_type: "seller",
      name: "Sched",
      message: "<p>Hi</p>",
      ready_to_publish: true,
      send_emails: true,
    )
    i.save!(validate: false)
    get :index
    assert_redirected_to scheduled_emails_path
  end
end
