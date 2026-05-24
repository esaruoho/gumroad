# frozen_string_literal: true

require "test_helper"

class Admin::BlockEmailDomainsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin = users(:admin_user)
    sign_in @admin
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::BlockEmailDomainsController.ancestors, Admin::BaseController
  end

  test "GET show renders mass-block page" do
    get :show
    assert_response :success
  end

  test "PATCH update enqueues block-object jobs and redirects with notice" do
    Sidekiq::Testing.fake! do
      BlockObjectWorker.jobs.clear
      patch :update, params: { email_domains: { identifiers: "spam.com other.com" } }
      assert_equal 2, BlockObjectWorker.jobs.size
    end
    assert_redirected_to admin_block_email_domains_url
    assert_response :see_other
    assert_equal "Email domains blocked successfully!", flash[:notice]
  end
end
