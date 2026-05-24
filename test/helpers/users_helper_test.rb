# frozen_string_literal: true

require "test_helper"

class UsersHelperTest < ActionView::TestCase
  tests UsersHelper

  test "allowed_avatar_extensions returns supported extensions joined by comma" do
    extensions = User::ALLOWED_AVATAR_EXTENSIONS.map { |ext| ".#{ext}" }.join(",")
    assert_equal extensions, allowed_avatar_extensions
  end

  test "signed_in_user_home returns dashboard path by default" do
    user = users(:basic_user)
    assert_equal Rails.application.routes.url_helpers.dashboard_path, signed_in_user_home(user)
  end

  test "signed_in_user_home returns next_url when present" do
    user = users(:basic_user)
    assert_equal "/sample", signed_in_user_home(user, next_url: "/sample")
  end

  test "signed_in_user_home returns library url with host when buyer and include_host" do
    user = users(:basic_user)
    user.define_singleton_method(:is_buyer?) { true }
    url = signed_in_user_home(user, include_host: true)
    assert_includes url, "/library"
    assert_match %r{^https?://}, url
  end

  test "signed_in_user_home returns dashboard url with host by default" do
    user = users(:basic_user)
    url = signed_in_user_home(user, include_host: true)
    assert_includes url, "/dashboard"
    assert_match %r{^https?://}, url
  end
end
