# frozen_string_literal: true

require "test_helper"

class User::SocialAppleTest < ActiveSupport::TestCase
  APPLE_UID = "001234.abcdef1234567890abcdef1234567890.1234"

  setup do
    WebMock.stub_request(:get, %r{api\.pwnedpasswords\.com/range/.+}).to_return(status: 200, body: "", headers: {})
  end

  def apple_data
    {
      "uid" => APPLE_UID,
      "info" => {
        "email" => "apple-user@example.com",
        "name" => "Jane Appleseed"
      }
    }
  end

  test "creates a new user with an external authentication when no matching user exists" do
    assert_difference -> { User.count }, 1 do
      User.find_or_create_for_apple_oauth(apple_data)
    end

    created_user = User.last
    assert_equal APPLE_UID, created_user.user_external_authentications.find_by(provider: "apple")&.uid
    assert_equal "apple-user@example.com", created_user.email
    assert_equal "Jane Appleseed", created_user.name
    assert_equal "apple", created_user.provider
    assert created_user.confirmed?
  end

  test "attaches past purchases with the same email" do
    purchase = purchases(:social_apple_unattached_purchase)
    assert_nil purchase.purchaser_id

    User.find_or_create_for_apple_oauth(apple_data)

    created_user = User.last
    assert_equal created_user.id, purchase.reload.purchaser_id
  end

  test "returns the existing user without creating a new one when uid matches" do
    existing_user = users(:another_seller)
    UserExternalAuthentication.create!(user: existing_user, provider: "apple", uid: APPLE_UID)

    assert_no_difference -> { User.count } do
      result = User.find_or_create_for_apple_oauth(apple_data)
      assert_equal existing_user, result
    end
  end

  test "links the apple authentication to an existing user with same email" do
    existing_user = users(:another_seller)
    existing_user.update_column(:email, "apple-user@example.com")

    result = User.find_or_create_for_apple_oauth(apple_data)

    assert_equal existing_user, result
    assert_equal APPLE_UID, existing_user.user_external_authentications.find_by(provider: "apple")&.uid
  end

  test "does not create a new user when email matches" do
    existing_user = users(:another_seller)
    existing_user.update_column(:email, "apple-user@example.com")

    assert_no_difference -> { User.count } do
      User.find_or_create_for_apple_oauth(apple_data)
    end
  end

  test "returns nil and notifies error tracker when uid is blank" do
    notified = false
    ErrorNotifier.stub(:notify, ->(msg) { notified = (msg == "Apple OAuth data is missing a uid") }) do
      result = User.find_or_create_for_apple_oauth({ "uid" => "", "info" => {} })
      assert_nil result
    end
    assert notified
  end

  test "creates a user without a name when name is nil" do
    data = apple_data.merge("info" => { "email" => "apple-user@example.com", "name" => nil })

    User.find_or_create_for_apple_oauth(data)

    created_user = User.last
    assert_predicate created_user.name, :blank?
  end

  test "does not overwrite the existing name on existing user" do
    existing_user = users(:another_seller)
    existing_user.update_columns(email: "apple-user@example.com", name: "Existing Name")

    User.find_or_create_for_apple_oauth(apple_data)

    assert_equal "Existing Name", existing_user.reload.name
  end
end
