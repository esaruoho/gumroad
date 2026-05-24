# frozen_string_literal: true

require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  tests ApplicationCable::Connection

  def setup
    @user = users(:basic_user)
    @gumroad_admin_user = users(:admin_user)
    @impersonated_user = users(:referrer_user)
  end

  def connect_with_user(user)
    session = user ? { "warden.user.user.key" => [[user.id], nil] } : {}
    connect session: session
  end

  test "#connect connects with valid user" do
    connect_with_user(@user)
    assert_equal @user, connection.current_user
  end

  test "#connect connects with gumroad admin when impersonation is not set" do
    connect_with_user(@gumroad_admin_user)
    assert_equal @gumroad_admin_user, connection.current_user
  end

  test "#connect connects with impersonated user when set" do
    $redis.set(RedisKey.impersonated_user(@gumroad_admin_user.id), @impersonated_user.id)
    connect_with_user(@gumroad_admin_user)
    assert_equal @impersonated_user, connection.current_user
  ensure
    $redis.del(RedisKey.impersonated_user(@gumroad_admin_user.id))
  end

  test "#connect connects with gumroad admin when impersonated user is not found" do
    $redis.set(RedisKey.impersonated_user(@gumroad_admin_user.id), -1)
    connect_with_user(@gumroad_admin_user)
    assert_equal @gumroad_admin_user, connection.current_user
  ensure
    $redis.del(RedisKey.impersonated_user(@gumroad_admin_user.id))
  end

  test "#connect connects with gumroad admin when impersonated user is not active" do
    @impersonated_user.update_columns(user_risk_state: "suspended_for_fraud")
    $redis.set(RedisKey.impersonated_user(@gumroad_admin_user.id), @impersonated_user.id)
    connect_with_user(@gumroad_admin_user)
    assert_equal @gumroad_admin_user, connection.current_user
  ensure
    $redis.del(RedisKey.impersonated_user(@gumroad_admin_user.id))
  end

  test "#connect rejects connection when user is not found" do
    assert_reject_connection { connect_with_user(nil) }
  end
end
