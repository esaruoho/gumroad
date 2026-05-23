# frozen_string_literal: true

require "test_helper"

class GmailAbuseFilterTest < ActiveSupport::TestCase
  teardown { $redis.del(GmailAbuseFilter::REDIS_KEY) }

  # --- .exists? ---
  test ".exists? returns true for a matching normalized email" do
    GmailAbuseFilter.add!("abuser@gmail.com")
    assert_equal true, GmailAbuseFilter.exists?("abuser@gmail.com")
  end

  test ".exists? returns true for plus-addressed variants" do
    GmailAbuseFilter.add!("abuser@gmail.com")
    assert_equal true, GmailAbuseFilter.exists?("abuser+spam@gmail.com")
  end

  test ".exists? returns true for dot variants" do
    GmailAbuseFilter.add!("abuser@gmail.com")
    assert_equal true, GmailAbuseFilter.exists?("a.b.u.s.e.r@gmail.com")
  end

  test ".exists? returns false for non-matching email" do
    GmailAbuseFilter.add!("abuser@gmail.com")
    assert_equal false, GmailAbuseFilter.exists?("innocent@gmail.com")
  end

  test ".exists? returns false for non-Gmail addresses" do
    GmailAbuseFilter.add!("abuser@gmail.com")
    assert_equal false, GmailAbuseFilter.exists?("abuser@example.com")
  end

  # --- .add! ---
  test ".add! adds the normalized email to the Redis set" do
    GmailAbuseFilter.add!("a.b.u.s.e.r+test@gmail.com")
    assert_equal true, $redis.sismember(GmailAbuseFilter::REDIS_KEY, "abuser@gmail.com")
  end

  test ".add! ignores non-Gmail addresses" do
    GmailAbuseFilter.add!("user@example.com")
    assert_equal 0, $redis.scard(GmailAbuseFilter::REDIS_KEY)
  end

  # --- .remove! ---
  test ".remove! removes the normalized email from the Redis set" do
    GmailAbuseFilter.add!("abuser@gmail.com")
    GmailAbuseFilter.remove!("abuser+old@gmail.com")
    assert_equal false, GmailAbuseFilter.exists?("abuser@gmail.com")
  end

  # --- .rebuild! (DB-backed) ---
  test ".rebuild! populates the set with normalized emails of abusive accounts" do
    users(:gmail_abuse_fraud_user)
    users(:gmail_abuse_tos_user)
    users(:gmail_abuse_flagged_user)

    GmailAbuseFilter.rebuild!

    assert_equal true, GmailAbuseFilter.exists?("fraud@gmail.com")
    assert_equal true, GmailAbuseFilter.exists?("tosviolator@gmail.com")
    assert_equal true, GmailAbuseFilter.exists?("flagged@gmail.com")
  end

  test ".rebuild! excludes compliant users" do
    users(:gmail_abuse_compliant_user)
    GmailAbuseFilter.rebuild!
    assert_equal false, GmailAbuseFilter.exists?("good@gmail.com")
  end

  test ".rebuild! excludes non-Gmail addresses" do
    users(:gmail_abuse_nongmail_user)
    GmailAbuseFilter.rebuild!
    assert_equal false, GmailAbuseFilter.exists?("nongmail@example.com")
  end

  test ".rebuild! replaces the previous set atomically" do
    users(:gmail_abuse_fraud_user)
    GmailAbuseFilter.add!("stale@gmail.com")
    GmailAbuseFilter.rebuild!
    assert_equal false, GmailAbuseFilter.exists?("stale@gmail.com")
  end
end
