# frozen_string_literal: true

require "test_helper"

class ResourceSubscriptionTest < ActiveSupport::TestCase
  setup do
    @user = users(:named_seller)
    @app = oauth_applications(:auth_presenter_app)
  end

  test "sets content_type to application/json for Zapier subscriptions" do
    rs = ResourceSubscription.create!(
      user: @user, oauth_application: @app,
      resource_name: "sale", post_url: "https://hooks.zapier.com/sample"
    )
    assert_equal "application/json", rs.content_type
  end

  test "doesn't overwrite the default content_type for non-Zapier subscriptions" do
    rs = ResourceSubscription.create!(
      user: @user, oauth_application: @app,
      resource_name: "sale", post_url: "https://hooks.example.com/sample"
    )
    assert_equal "application/x-www-form-urlencoded", rs.content_type
  end
end
