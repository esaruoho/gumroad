# frozen_string_literal: true

require "test_helper"

class GithubStarsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    Rails.cache.write("github_stars_antiwork/gumroad", 5818)
  end

  teardown do
    Rails.cache.delete("github_stars_antiwork/gumroad")
  end

  test "renders HTTP success" do
    get :show
    assert_response :success
    assert_includes @response.content_type, "application/json"
    assert_equal 5818, @response.parsed_body["stars"]
    assert_includes @response.headers["Cache-Control"], "max-age=3600, public"
  end
end
