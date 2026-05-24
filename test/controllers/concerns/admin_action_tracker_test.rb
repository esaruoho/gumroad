# frozen_string_literal: true

require "test_helper"

class AdminActionTrackerTestAnonymousController < ApplicationController
  include AdminActionTracker

  def index
    head :ok
  end
end

class AdminActionTrackerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.routes.draw do
      get "admin_action_tracker_test_anonymous", to: "admin_action_tracker_test_anonymous#index"
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  test "calling an action increments the call_count" do
    record = AdminActionCallInfo.create!(
      controller_name: "AdminActionTrackerTestAnonymousController",
      action_name: "index",
      call_count: 0
    )

    get "/admin_action_tracker_test_anonymous"
    assert_equal 1, record.reload.call_count
  end
end
