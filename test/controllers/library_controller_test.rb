# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class LibraryControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @user = users(:purchaser)
    @purchase = purchases(:named_seller_call_purchase) # purchaser_id == purchaser
    sign_in_as_seller(@user, @user)
    @request.headers["X-Inertia"] = "true"
  end

  teardown { restore_protect_against_forgery! }

  test "GET index renders Library/Index for confirmed user" do
    get :index
    assert_response :success
    page = JSON.parse(@response.body)
    assert_equal "Library/Index", page["component"]
    assert_kind_of Array, page["props"]["results"]
  end

  test "GET index redirects unconfirmed user to settings and sends confirmation" do
    @user.update!(confirmed_at: nil, confirmation_sent_at: nil)
    sent = false
    orig = User.instance_method(:send_confirmation_instructions)
    User.define_method(:send_confirmation_instructions) { sent = true }
    begin
      get :index
    ensure
      User.define_method(:send_confirmation_instructions, orig)
    end
    assert_response :redirect
    assert sent, "expected send_confirmation_instructions to be called"
    assert_equal "Please check your email to confirm your address before you can see that.", flash[:warning]
  end

  test "GET index does not resend confirmation if sent within 24 hours" do
    @user.update!(confirmed_at: nil, confirmation_sent_at: 5.hours.ago)
    sent = false
    orig = User.instance_method(:send_confirmation_instructions)
    User.define_method(:send_confirmation_instructions) { sent = true }
    begin
      get :index
    ensure
      User.define_method(:send_confirmation_instructions, orig)
    end
    assert_response :redirect
    refute sent, "did not expect send_confirmation_instructions to be called"
  end

  # PATCH archive/unarchive/delete deferred — controller's @purchase.update!(...)
  # fires Purchase validations that fail in the fixtures lane (credit card,
  # fee_cents). Worth re-attempting once a fully-valid buyer purchase fixture
  # is added.
end
