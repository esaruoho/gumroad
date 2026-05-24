# frozen_string_literal: true

require "test_helper"

class User::AsJsonTest < ActiveSupport::TestCase
  COMMON_KEYS = %w[name bio twitter_handle id user_id url profile_picture_url links].freeze
  API_SCOPE_KEYS = %w[currency_type profile_url email].freeze
  INTERNAL_USE_KEYS = %w[created_at sign_in_count current_sign_in_at last_sign_in_at current_sign_in_ip last_sign_in_ip purchases_count successful_purchases_count].freeze

  setup do
    @user = users(:as_json_user)
    # Touch the linked product so reads work
    links(:as_json_user_product)
  end

  # --- for api :edit_products ---

  test "edit_products: returns the correct hash" do
    json = @user.as_json(api_scopes: ["edit_products"])
    %w[name email].each { |k| assert json.key?(k) }
    assert_equal ["boo"], json["links"]
  end

  test "edit_products: returns an alphanumeric id" do
    json = @user.as_json(api_scopes: ["edit_products"])
    assert_equal ObfuscateIds.encrypt(@user.id), json["user_id"]
  end

  # --- public ---

  test "public: returns the correct hash with name" do
    json = @user.as_json
    assert json.key?("name")
  end

  test "public: returns an alphanumeric id" do
    json = @user.as_json
    assert_equal ObfuscateIds.encrypt(@user.id), json["user_id"]
  end

  # --- view_sales ---

  test "view_sales: returns the email" do
    json = @user.as_json(api_scopes: ["view_sales"])
    assert json.key?("email")
  end

  # --- view_profile ---

  test "view_profile: returns view_profile-specific keys" do
    json = @user.as_json(api_scopes: ["view_profile"])
    %w[email profile_url display_name id].each { |k| assert json.key?(k) }
  end

  # --- returned keys: no options, no bio/twitter ---

  test "no options, no bio/twitter: returns common values minus bio/twitter" do
    keys = @user.as_json.keys.map(&:to_s)
    assert_equal (COMMON_KEYS - %w[bio twitter_handle]).sort, keys.sort
  end

  test "no options, bio set: returns common values except twitter_handle" do
    user = users(:as_json_user_with_bio)
    links(:as_json_user_with_bio_product)
    keys = user.as_json.keys.map(&:to_s)
    assert_equal (COMMON_KEYS - %w[twitter_handle]).sort, keys.sort
  end

  test "no options, twitter set: returns common values except bio" do
    user = users(:as_json_user_with_twitter)
    links(:as_json_user_with_twitter_product)
    keys = user.as_json.keys.map(&:to_s)
    assert_equal (COMMON_KEYS - %w[bio]).sort, keys.sort
  end

  # --- internal_use only ---

  test "internal_use only: returns all common + api_scope + internal_use keys" do
    keys = @user.as_json(internal_use: true).keys.map(&:to_s)
    assert_equal (COMMON_KEYS + API_SCOPE_KEYS + INTERNAL_USE_KEYS).sort, keys.sort
  end

  # --- per-scope expectations ---

  %w[edit_products view_sales revenue_share ifttt view_profile].each do |api_scope|
    test "#{api_scope} + internal_use: returns expected keys" do
      keys = @user.as_json(api_scopes: [api_scope], internal_use: true).keys.map(&:to_s)
      expected = COMMON_KEYS + API_SCOPE_KEYS + INTERNAL_USE_KEYS
      expected += %w[display_name] if api_scope == "view_profile"
      assert_equal expected.sort, keys.sort
    end

    test "#{api_scope} without internal_use: returns expected keys" do
      keys = @user.as_json(api_scopes: [api_scope]).keys.map(&:to_s)
      expected = COMMON_KEYS + API_SCOPE_KEYS
      expected += %w[display_name] if api_scope == "view_profile"
      assert_equal expected.sort, keys.sort
    end
  end
end
