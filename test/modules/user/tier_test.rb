# frozen_string_literal: true

require "test_helper"

class UserTierTest < ActiveSupport::TestCase
  def fresh_user(tier_state: nil)
    u = users(:basic_user)
    u.update_column(:tier_state, tier_state) if tier_state
    u.reload
  end

  test "tier upgrades to next tier" do
    user = fresh_user(tier_state: User::TIER_0)
    assert_equal User::TIER_0, user.tier
    assert_equal true, user.upgrade_tier
    assert_equal User::TIER_1, user.tier
  end

  test "tier upgrades with tier override" do
    user = fresh_user(tier_state: User::TIER_0)
    assert_equal User::TIER_0, user.tier
    assert_equal true, user.upgrade_tier(User::TIER_2)
    assert_equal User::TIER_2, user.tier
  end

  test "tier does not upgrade if tier is 1M" do
    user = fresh_user(tier_state: User::TIER_4)
    assert_equal false, user.upgrade_tier
  end

  test "tier rejects upgrade if tier does not change" do
    user = fresh_user(tier_state: User::TIER_1)
    assert_raises(ArgumentError) { user.upgrade_tier(User::TIER_1) }
  end

  test "tier rejects invalid tier in transition argument" do
    user = fresh_user(tier_state: User::TIER_0)
    assert_raises(ArgumentError) { user.upgrade_tier(1234) }
  end

  test "tier rejects invalid upgrade (downgrade)" do
    user = fresh_user(tier_state: User::TIER_3)
    assert_raises(ArgumentError) { user.upgrade_tier(User::TIER_2) }
  end

  test "#tier returns 0 if creator has not received any payments" do
    creator = fresh_user(tier_state: User::TIER_0)
    assert_equal 0, creator.tier
  end

  test "#tier returns 0 if creator has negative sales" do
    creator = fresh_user(tier_state: User::TIER_0)
    assert_equal 0, creator.tier(-1000)
  end

  test "#tier returns value from tier_state column" do
    creator = fresh_user(tier_state: User::TIER_1)
    assert_equal User::TIER_1, creator.tier_state
    assert_equal User::TIER_1, creator.tier
  end

  test "#tier returns correct tier based on revenue" do
    creator = fresh_user(tier_state: User::TIER_0)
    assert_equal User::TIER_0, creator.tier(0)
    assert_equal User::TIER_0, creator.tier(999_00)
    assert_equal User::TIER_1, creator.tier(1_000_00)
    assert_equal User::TIER_1, creator.tier(9_999_00)
    assert_equal User::TIER_2, creator.tier(10_000_00)
    assert_equal User::TIER_2, creator.tier(99_999_00)
    assert_equal User::TIER_3, creator.tier(100_000_00)
    assert_equal User::TIER_3, creator.tier(999_999_00)
    assert_equal User::TIER_4, creator.tier(1_000_000_00)
    assert_equal User::TIER_4, creator.tier(10_000_000_00)
  end
end
