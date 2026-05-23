# frozen_string_literal: true

require "test_helper"

class Admin::SuspendUsersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin_user = users(:admin_user)
    @user1 = users(:suspend_target_one)
    @user2 = users(:suspend_target_two)
    sign_in @admin_user
    @request.headers["X-Inertia"] = "true"
    SuspendUsersWorker.jobs.clear
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::SuspendUsersController.ancestors, Admin::BaseController
  end

  test "GET show renders the page" do
    get :show
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal "Admin/SuspendUsers/Show", body["component"]
    props = body["props"]
    assert_equal "Mass-suspend users", props["title"]
    assert_equal([
                   "Violating our terms of service",
                   "Creating products that violate our ToS",
                   "Using Gumroad to commit fraud",
                   "Using Gumroad for posting spam or SEO manipulation",
                 ], props["suspend_reasons"])
    assert_predicate props["authenticity_token"], :present?
  end

  def user_ids
    [@user1.id.to_s, @user2.id.to_s]
  end

  def reason
    "Violating our terms of service"
  end

  def do_update(specified_ids, additional_notes: nil, scheduled_payout: nil)
    params = { suspend_users: { identifiers: specified_ids, reason: reason, additional_notes: additional_notes } }
    params[:scheduled_payout] = scheduled_payout if scheduled_payout
    put :update, params: params
  end

  def assert_job_args(expected_user_ids, expected_notes, expected_sp)
    assert_equal 1, SuspendUsersWorker.jobs.size
    args = SuspendUsersWorker.jobs.last["args"]
    assert_equal [@admin_user.id, expected_user_ids, reason, expected_notes, expected_sp], args
  end

  test "PUT update enqueues a job (newline-separated IDs)" do
    do_update(user_ids.join("\n"))
    assert_job_args(user_ids, nil, nil)
    assert_equal "User suspension in progress!", flash[:notice]
    assert_redirected_to admin_suspend_users_url
  end

  test "PUT update enqueues a job (comma-separated IDs)" do
    do_update(user_ids.join(", "))
    assert_job_args(user_ids, nil, nil)
    assert_equal "User suspension in progress!", flash[:notice]
    assert_redirected_to admin_suspend_users_url
  end

  test "PUT update accepts external IDs" do
    external_ids = [@user1.external_id, @user2.external_id]
    do_update(external_ids.join(", "))
    assert_job_args(external_ids, nil, nil)
    assert_equal "User suspension in progress!", flash[:notice]
    assert_redirected_to admin_suspend_users_url
  end

  test "PUT update passes additional notes" do
    do_update(user_ids.join(", "), additional_notes: "Some additional notes")
    assert_job_args(user_ids, "Some additional notes", nil)
  end

  test "PUT update forwards scheduled payout params (payout action)" do
    do_update(user_ids.join(", "), scheduled_payout: { action: "payout", delay_days: "14" })
    assert_job_args(user_ids, nil, { "action" => "payout", "delay_days" => "14" })
  end

  test "PUT update forwards hold action with nil delay_days when blank" do
    do_update(user_ids.join(", "), scheduled_payout: { action: "hold", delay_days: "" })
    assert_job_args(user_ids, nil, { "action" => "hold", "delay_days" => nil })
  end

  test "PUT update ignores scheduled payout when action blank" do
    do_update(user_ids.join(", "), scheduled_payout: { action: "", delay_days: "14" })
    assert_job_args(user_ids, nil, nil)
  end
end
