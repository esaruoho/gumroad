# frozen_string_literal: true

require "test_helper"

class FeatureTest < ActiveSupport::TestCase
  fixtures :users

  FEATURE_NAME = :new_feature

  def setup
    reset_feature
  end

  def teardown
    reset_feature
  end

  def reset_feature
    Flipper.disable(FEATURE_NAME)
    Flipper[FEATURE_NAME].remove
  rescue StandardError
    # best-effort cleanup
  end

  def user1
    users(:basic_user)
  end

  def user2
    users(:reset_user)
  end

  # ----- #activate -----

  test "#activate activates the feature for everyone" do
    assert_equal false, Flipper.enabled?(FEATURE_NAME)
    Feature.activate(FEATURE_NAME)
    assert_equal true, Flipper.enabled?(FEATURE_NAME)
  end

  # ----- #activate_user -----

  test "#activate_user activates the feature for the actor" do
    assert_equal false, Flipper.enabled?(FEATURE_NAME, user1)
    Feature.activate_user(FEATURE_NAME, user1)
    assert_equal false, Flipper.enabled?(FEATURE_NAME)
    assert_equal true, Flipper.enabled?(FEATURE_NAME, user1)
  end

  # ----- #deactivate -----

  test "#deactivate deactivates the feature for everyone" do
    Flipper.enable(FEATURE_NAME)
    assert_equal true, Flipper.enabled?(FEATURE_NAME, user1)
    assert_equal true, Flipper.enabled?(FEATURE_NAME, user2)
    assert_equal true, Flipper.enabled?(FEATURE_NAME)
    Feature.deactivate(FEATURE_NAME)
    assert_equal false, Flipper.enabled?(FEATURE_NAME, user1)
    assert_equal false, Flipper.enabled?(FEATURE_NAME, user2)
    assert_equal false, Flipper.enabled?(FEATURE_NAME)
  end

  # ----- #deactivate_user -----

  test "#deactivate_user deactivates the feature for the actor" do
    Flipper.enable_actor(FEATURE_NAME, user1)
    Flipper.enable_actor(FEATURE_NAME, user2)
    Feature.deactivate_user(FEATURE_NAME, user1)
    assert_equal false, Flipper.enabled?(FEATURE_NAME, user1)
    assert_equal true, Flipper.enabled?(FEATURE_NAME, user2)
  end

  # ----- #activate_percentage -----

  test "#activate_percentage activates the feature for the specified percentage of actors" do
    assert_equal 0, Flipper[FEATURE_NAME].percentage_of_actors_value
    Feature.activate_percentage(FEATURE_NAME, 100)
    assert_equal 100, Flipper[FEATURE_NAME].percentage_of_actors_value
  end

  # ----- #deactivate_percentage -----

  test "#deactivate_percentage deactivates the percentage rollout" do
    Feature.activate_percentage(FEATURE_NAME, 100)
    assert_equal 100, Flipper[FEATURE_NAME].percentage_of_actors_value
    Feature.deactivate_percentage(FEATURE_NAME)
    assert_equal 0, Flipper[FEATURE_NAME].percentage_of_actors_value
  end

  # ----- #active? -----

  test "#active? with actor: true if feature is active for the actor" do
    Flipper.enable_actor(FEATURE_NAME, user1)
    assert_equal true, Feature.active?(FEATURE_NAME, user1)
  end

  test "#active? with actor: false if feature is not active for the actor" do
    assert_equal false, Feature.active?(FEATURE_NAME, user1)
  end

  test "#active? without actor: true if feature is active for everyone" do
    Flipper.enable(FEATURE_NAME)
    assert_equal true, Feature.active?(FEATURE_NAME)
  end

  test "#active? without actor: false if feature is not active for everyone" do
    assert_equal false, Feature.active?(FEATURE_NAME)
  end

  # ----- #inactive? -----

  test "#inactive? with actor: false if feature is active for the actor" do
    Flipper.enable_actor(FEATURE_NAME, user1)
    assert_equal false, Feature.inactive?(FEATURE_NAME, user1)
  end

  test "#inactive? with actor: true if feature is not active for the actor" do
    assert_equal true, Feature.inactive?(FEATURE_NAME, user1)
  end

  test "#inactive? without actor: false if feature is active for everyone" do
    Flipper.enable(FEATURE_NAME)
    assert_equal false, Feature.inactive?(FEATURE_NAME)
  end

  test "#inactive? without actor: true if feature is not active for everyone" do
    assert_equal true, Feature.inactive?(FEATURE_NAME)
  end
end
