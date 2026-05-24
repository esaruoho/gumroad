# frozen_string_literal: true

require "test_helper"

class Affiliate::SortingTest < ActiveSupport::TestCase
  setup do
    @seller = users(:affiliate_sorting_seller)
    @aff1 = affiliates(:affiliate_sorting_aff_1)
    @aff2 = affiliates(:affiliate_sorting_aff_2)
    @aff3 = affiliates(:affiliate_sorting_aff_3)
  end

  def sorted(key, direction)
    @seller.direct_affiliates.sorted_by(key: key, direction: direction).to_a
  end

  test "returns affiliates sorted by the affiliate user's name" do
    order = [@aff1, @aff2, @aff3]
    assert_equal order, sorted("affiliate_user_name", "asc")
    assert_equal order.reverse, sorted("affiliate_user_name", "desc")
  end

  test "sorted by unconfirmed email when name/username blank" do
    @aff1.affiliate_user.update_columns(name: nil, username: nil, unconfirmed_email: "bob@example.com", email: nil)
    @aff2.affiliate_user.update_columns(name: nil, username: nil, unconfirmed_email: "charlie@example.com", email: nil)
    @aff3.affiliate_user.update_columns(name: nil, username: nil, unconfirmed_email: "alice@example.com", email: nil)
    order = [@aff3, @aff1, @aff2]
    assert_equal order, sorted("affiliate_user_name", "asc")
    assert_equal order.reverse, sorted("affiliate_user_name", "desc")
  end

  test "sorted by email when name/username and unconfirmed_email blank" do
    @aff1.affiliate_user.update_columns(name: nil, username: nil, email: "bob@example.com", unconfirmed_email: nil)
    @aff2.affiliate_user.update_columns(name: nil, username: nil, email: "charlie@example.com", unconfirmed_email: nil)
    @aff3.affiliate_user.update_columns(name: nil, username: nil, email: "alice@example.com", unconfirmed_email: nil)
    order = [@aff3, @aff1, @aff2]
    assert_equal order, sorted("affiliate_user_name", "asc")
    assert_equal order.reverse, sorted("affiliate_user_name", "desc")
  end

  test "sorted by username when name absent and custom username set" do
    @aff1.affiliate_user.update_columns(name: nil, email: nil, username: "charlie", unconfirmed_email: nil)
    @aff2.affiliate_user.update_columns(name: nil, email: nil, username: "bob", unconfirmed_email: nil)
    @aff3.affiliate_user.update_columns(name: nil, email: nil, username: "alice", unconfirmed_email: nil)
    order = [@aff3, @aff2, @aff1]
    assert_equal order, sorted("affiliate_user_name", "asc")
    assert_equal order.reverse, sorted("affiliate_user_name", "desc")
  end

  test "sorted by number of products" do
    order = [@aff1, @aff3, @aff2]
    assert_equal order, sorted("products", "asc")
    assert_equal order.reverse, sorted("products", "desc")
  end

  test "sorted by lowest product commission percentage" do
    order = [@aff3, @aff2, @aff1]
    assert_equal order, sorted("fee_percent", "asc")
    assert_equal order.reverse, sorted("fee_percent", "desc")
  end

  test "sorted by total sales" do
    order = [@aff3, @aff1, @aff2]
    assert_equal order, sorted("volume_cents", "asc")
    assert_equal order.reverse, sorted("volume_cents", "desc")
  end
end
