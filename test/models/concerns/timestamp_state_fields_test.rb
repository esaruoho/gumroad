require "test_helper"

class TimestampStateFieldsTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  class TestTimestampUser < ApplicationRecord
    self.table_name = "users"

    include TimestampStateFields
    timestamp_state_fields \
      :created,
      :confirmed,
      :banned,
      :deleted,
      default_state: :confirmed,
      states_excluded_from_default: %i[created]
  end

  setup do
    @user = TestTimestampUser.create!(
      name: "Joe",
      email: "joe-#{SecureRandom.hex(4)}@example.com",
      recommendation_type: User::RecommendationType::OWN_PRODUCTS
    )
  end

  teardown do
    @user&.destroy
  end

  test "class methods filter records" do
    @user.update_as_banned!
    assert_equal [@user], TestTimestampUser.banned.to_a
    assert_equal [], TestTimestampUser.not_banned.where(id: @user.id).to_a
  end

  test "instance methods: returns boolean value when using predicate methods" do
    assert_equal true, @user.created?
    assert_equal false, @user.not_created?
  end

  test "instance methods: updates record via update methods" do
    assert_equal false, @user.banned?
    @user.update_as_banned!
    assert_equal true, @user.banned?
    @user.update_as_not_banned!
    assert_equal false, @user.banned?
  end

  test "instance methods: responds to state methods" do
    assert_equal true, @user.created?
    assert_equal true, @user.state_confirmed?
    assert_equal :confirmed, @user.state

    assert_equal false, @user.banned?
    assert_equal false, @user.deleted?

    @user.update_as_banned!
    assert_equal :banned, @user.state
    assert_equal true, @user.state_banned?
  end
end
