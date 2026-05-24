# frozen_string_literal: true

require "test_helper"

class User::EmailNormalizationTest < ActiveSupport::TestCase
  setup do
    # Devise's pwned_password check otherwise hits api.pwnedpasswords.com.
    WebMock.stub_request(:get, %r{api\.pwnedpasswords\.com/range/}).to_return(status: 200, body: "", headers: {})
  end

  def build_user(email:)
    User.new(
      email: email,
      password: "-42Q_.c_3628Ca!mW-xTJ8v*",
      confirmed_at: Time.current,
      user_risk_state: "not_reviewed",
    )
  end

  # --- .normalize_gmail_address ---

  test "strips plus-addressing from Gmail addresses" do
    assert_equal "user@gmail.com", User.normalize_gmail_address("user+suffix@gmail.com")
  end

  test "removes dots from Gmail local parts" do
    assert_equal "user@gmail.com", User.normalize_gmail_address("u.s.e.r@gmail.com")
  end

  test "handles both plus-addressing and dots together" do
    assert_equal "user@gmail.com", User.normalize_gmail_address("u.s.e.r+suffix@gmail.com")
  end

  test "normalizes googlemail.com to gmail.com" do
    assert_equal "user@gmail.com", User.normalize_gmail_address("user+test@googlemail.com")
  end

  test "downcases the email" do
    assert_equal "user@gmail.com", User.normalize_gmail_address("User+Test@Gmail.com")
  end

  test "returns the original email downcased for non-Gmail domains" do
    assert_equal "user+test@example.com", User.normalize_gmail_address("user+test@example.com")
  end

  test "returns nil for blank input" do
    assert_nil User.normalize_gmail_address("")
    assert_nil User.normalize_gmail_address(nil)
  end

  # --- .abusive_gmail_variant_exists? ---

  test "detects plus-addressed variants when in Redis set" do
    GmailAbuseFilter.add!("abuser@gmail.com")
    assert User.abusive_gmail_variant_exists?("abuser+random123@gmail.com")
  ensure
    $redis.del(GmailAbuseFilter::REDIS_KEY)
  end

  test "detects dot variants when in Redis set" do
    GmailAbuseFilter.add!("abuser@gmail.com")
    assert User.abusive_gmail_variant_exists?("a.b.u.s.e.r@gmail.com")
  ensure
    $redis.del(GmailAbuseFilter::REDIS_KEY)
  end

  test "detects combined plus and dot variants when in Redis set" do
    GmailAbuseFilter.add!("abuser@gmail.com")
    assert User.abusive_gmail_variant_exists?("a.b.u.s.e.r+test@gmail.com")
  ensure
    $redis.del(GmailAbuseFilter::REDIS_KEY)
  end

  test "returns false when not in Redis set" do
    refute User.abusive_gmail_variant_exists?("gooduser+test@gmail.com")
  end

  test "returns false for non-Gmail addresses" do
    refute User.abusive_gmail_variant_exists?("abuser+test@example.com")
  end

  # --- email_not_from_suspended_gmail_variant validation ---

  test "blocks signup with plus-addressed variant when flag enabled and filter matches" do
    Feature.activate(:block_gmail_abuse_at_signup)
    GmailAbuseFilter.add!("scammer@gmail.com")
    user = build_user(email: "scammer+new@gmail.com")
    user.valid?(:create)
    assert_includes user.errors[:base], "Something went wrong."
  ensure
    Feature.deactivate(:block_gmail_abuse_at_signup)
    $redis.del(GmailAbuseFilter::REDIS_KEY)
  end

  test "blocks signup with dot variant when flag enabled and filter matches" do
    Feature.activate(:block_gmail_abuse_at_signup)
    GmailAbuseFilter.add!("scammer@gmail.com")
    user = build_user(email: "s.c.a.m.m.e.r@gmail.com")
    user.valid?(:create)
    assert_includes user.errors[:base], "Something went wrong."
  ensure
    Feature.deactivate(:block_gmail_abuse_at_signup)
    $redis.del(GmailAbuseFilter::REDIS_KEY)
  end

  test "allows signup when no matching email in filter" do
    Feature.activate(:block_gmail_abuse_at_signup)
    user = build_user(email: "newuser+tag@gmail.com")
    user.valid?(:create)
    assert_empty user.errors[:base]
  ensure
    Feature.deactivate(:block_gmail_abuse_at_signup)
    $redis.del(GmailAbuseFilter::REDIS_KEY)
  end

  test "skips validation when feature flag disabled" do
    Feature.deactivate(:block_gmail_abuse_at_signup)
    GmailAbuseFilter.add!("scammer@gmail.com")
    user = build_user(email: "scammer+new@gmail.com")
    user.valid?(:create)
    assert_empty user.errors[:base]
  ensure
    $redis.del(GmailAbuseFilter::REDIS_KEY)
  end
end
