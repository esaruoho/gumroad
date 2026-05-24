# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class InstantPayoutsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    sign_in_as_seller(@seller, @seller)
    @date = 1.day.ago.to_date
  end

  teardown { restore_protect_against_forgery! }

  def stub_service(result)
    fake = Object.new
    fake.define_singleton_method(:perform) { result }
    @orig_new = InstantPayoutsService.method(:new)
    InstantPayoutsService.define_singleton_method(:new) { |_seller, **_opts| fake }
  end

  teardown do
    InstantPayoutsService.define_singleton_method(:new, @orig_new) if @orig_new
  end

  test "POST create redirects to balance with success notice on success" do
    stub_service(success: true)
    post :create, params: { date: @date.to_s }
    assert_redirected_to balance_path
    assert_equal "Instant payout initiated successfully", flash[:notice]
  end

  test "POST create redirects to balance with error alert on failure" do
    stub_service(success: false, error: "Error message")
    post :create, params: { date: @date.to_s }
    assert_redirected_to balance_path
    assert_equal "Error message", flash[:alert]
  end
end
