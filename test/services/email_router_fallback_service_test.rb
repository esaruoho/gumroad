# frozen_string_literal: true

require "test_helper"

class EmailRouterFallbackServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:basic_user)
    EmailRouterFallbackService.clear(user: @user)
  end

  teardown do
    EmailRouterFallbackService.clear(user: @user)
  end

  test ".email_provider_for_two_factor returns nil when feature flag is inactive" do
    Feature.deactivate(:resend_fallback_for_auth_emails)
    EmailRouterFallbackService.record_email_sent(user: @user)

    assert_nil EmailRouterFallbackService.email_provider_for_two_factor(user: @user)
  end

  test ".email_provider_for_two_factor returns nil when no previous email was sent" do
    Feature.activate(:resend_fallback_for_auth_emails)

    assert_nil EmailRouterFallbackService.email_provider_for_two_factor(user: @user)
  ensure
    Feature.deactivate(:resend_fallback_for_auth_emails)
  end

  test ".email_provider_for_two_factor returns Resend provider when Redis key exists" do
    Feature.activate(:resend_fallback_for_auth_emails)
    EmailRouterFallbackService.record_email_sent(user: @user)

    assert_equal MailerInfo::EMAIL_PROVIDER_RESEND,
                 EmailRouterFallbackService.email_provider_for_two_factor(user: @user)
  ensure
    Feature.deactivate(:resend_fallback_for_auth_emails)
  end

  test ".email_provider_for_two_factor tracks different users separately" do
    Feature.activate(:resend_fallback_for_auth_emails)
    other_user = users(:another_seller)
    EmailRouterFallbackService.clear(user: other_user)
    EmailRouterFallbackService.record_email_sent(user: @user)

    assert_equal MailerInfo::EMAIL_PROVIDER_RESEND,
                 EmailRouterFallbackService.email_provider_for_two_factor(user: @user)
    assert_nil EmailRouterFallbackService.email_provider_for_two_factor(user: other_user)
  ensure
    Feature.deactivate(:resend_fallback_for_auth_emails)
  end

  test ".record_email_sent stores the current timestamp in Redis" do
    travel_to Time.current do
      EmailRouterFallbackService.record_email_sent(user: @user)
      stored_value = $redis.get(RedisKey.email_router_fallback(@user.id))
      assert_equal Time.current.to_i, Time.zone.parse(stored_value).to_i
    end
  end

  test ".record_email_sent sets 5 minute TTL on the key" do
    EmailRouterFallbackService.record_email_sent(user: @user)

    ttl = $redis.ttl(RedisKey.email_router_fallback(@user.id))
    assert ttl.between?(290, 300), "TTL #{ttl} not in [290,300]"
  end

  test ".clear removes the tracking key from Redis" do
    EmailRouterFallbackService.record_email_sent(user: @user)
    assert $redis.get(RedisKey.email_router_fallback(@user.id)).present?

    EmailRouterFallbackService.clear(user: @user)

    assert_nil $redis.get(RedisKey.email_router_fallback(@user.id))
  end
end
