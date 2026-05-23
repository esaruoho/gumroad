# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  tests ApplicationHelper

  test "current_user_props returns the current user props" do
    admin = users(:admin_user)
    admin.update_column(:username, "gumroadian")
    seller = users(:named_seller)

    props = current_user_props(admin, seller)
    assert_equal "gumroadian", props[:name]
    assert_equal admin.avatar_url, props[:avatar_url]
    assert_equal "Seller", props[:impersonated_user][:name]
    assert_equal seller.avatar_url, props[:impersonated_user][:avatar_url]
  end

  test "number_to_si returns numbers < 1000 as is" do
    assert_equal "0", number_to_si(0)
    assert_equal "123", number_to_si(123)
    assert_equal "999", number_to_si(999)
  end

  test "number_to_si uses K suffix for thousands" do
    assert_equal "1K", number_to_si(1000)
    assert_equal "1.1K", number_to_si(1100)
    assert_equal "10K", number_to_si(10000)
    assert_equal "10.1K", number_to_si(10100)
    assert_equal "10K", number_to_si(10010)
  end

  test "number_to_si uses M suffix for millions" do
    assert_equal "1M", number_to_si(1_000_000)
    assert_equal "1M", number_to_si(1_002_000)
    assert_equal "1.2M", number_to_si(1_200_000)
  end

  test "number_to_si does not round up" do
    assert_equal "99.9K", number_to_si(99_999)
    assert_equal "999.9K", number_to_si(999_999)
    assert_equal "9.9M", number_to_si(9_999_999)
  end
end
