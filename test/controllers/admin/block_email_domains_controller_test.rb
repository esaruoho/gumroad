# frozen_string_literal: true

require "test_helper"

class Admin::BlockEmailDomainsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin_user = users(:admin_user)
    sign_in @admin_user
    @request.headers["X-Inertia"] = "true"
    BlockObjectWorker.jobs.clear
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::BlockEmailDomainsController.ancestors, Admin::BaseController
  end

  test "GET show renders the page" do
    get :show
    assert_response :success
    assert_equal "Admin/BlockEmailDomains/Show", JSON.parse(@response.body)["component"]
  end

  test "PUT update enqueues jobs when identifiers separated by newlines" do
    put :update, params: { email_domains: { identifiers: "example.com\nexample.org" } }
    assert_equal 2, BlockObjectWorker.jobs.size
    assert_redirected_to admin_block_email_domains_url
    assert_equal "Email domains blocked successfully!", flash[:notice]
  end

  test "PUT update enqueues jobs when identifiers separated by commas" do
    put :update, params: { email_domains: { identifiers: "example.com, example.org" } }
    assert_equal 2, BlockObjectWorker.jobs.size
    assert_redirected_to admin_block_email_domains_url
    assert_equal "Email domains blocked successfully!", flash[:notice]
  end

  test "PUT update calls perform_bulk with correct args (newline separated)" do
    expected_args = [["email_domain", "example.com", @admin_user.id], ["email_domain", "example.org", @admin_user.id]]
    captured = nil
    BlockObjectWorker.singleton_class.alias_method :_orig_perform_bulk, :perform_bulk
    BlockObjectWorker.define_singleton_method(:perform_bulk) do |args, **opts|
      captured = [args, opts]
      _orig_perform_bulk(args, **opts)
    end
    put :update, params: { email_domains: { identifiers: "example.com\nexample.org" } }
    assert_equal expected_args, captured[0]
    assert_equal({ batch_size: 1_000 }, captured[1])
  ensure
    BlockObjectWorker.singleton_class.class_eval do
      remove_method :perform_bulk
      alias_method :perform_bulk, :_orig_perform_bulk
      remove_method :_orig_perform_bulk
    end
  end

  test "PUT update calls perform_bulk with correct args (comma separated)" do
    expected_args = [["email_domain", "example.com", @admin_user.id], ["email_domain", "example.org", @admin_user.id]]
    captured = nil
    BlockObjectWorker.singleton_class.alias_method :_orig_perform_bulk, :perform_bulk
    BlockObjectWorker.define_singleton_method(:perform_bulk) do |args, **opts|
      captured = [args, opts]
      _orig_perform_bulk(args, **opts)
    end
    put :update, params: { email_domains: { identifiers: "example.com, example.org" } }
    assert_equal expected_args, captured[0]
  ensure
    BlockObjectWorker.singleton_class.class_eval do
      remove_method :perform_bulk
      alias_method :perform_bulk, :_orig_perform_bulk
      remove_method :_orig_perform_bulk
    end
  end
end
