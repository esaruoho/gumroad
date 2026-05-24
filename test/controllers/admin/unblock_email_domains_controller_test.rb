# frozen_string_literal: true

require "test_helper"

class Admin::UnblockEmailDomainsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin_user = users(:admin_user)
    sign_in @admin_user
    @request.headers["X-Inertia"] = "true"
    UnblockObjectWorker.jobs.clear
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::UnblockEmailDomainsController.ancestors, Admin::BaseController
  end

  test "GET show renders the page" do
    get :show
    assert_response :success
    assert_equal "Admin/UnblockEmailDomains/Show", JSON.parse(@response.body)["component"]
  end

  test "PUT update enqueues a job to unsuspend the specified email domains" do
    put :update, params: { email_domains: { identifiers: "example.com\nexample.org" } }
    assert_equal 2, UnblockObjectWorker.jobs.size
    assert_redirected_to admin_unblock_email_domains_url
    assert_equal "Email domains unblocked successfully!", flash[:notice]
  end

  test "PUT update unblocks email domain" do
    PlatformBlock.add!(object_type: PlatformBlock::TYPES[:email_domain], object_value: "example.com")
    Sidekiq::Testing.inline! do
      put :update, params: { email_domains: { identifiers: "example.com\nexample.org" } }
    end
    record = PlatformBlock.find_by(object_value: "example.com")
    assert_not_nil record
    assert_nil record.blocked_at
  end
end
