# frozen_string_literal: true

require "test_helper"

class DisposableEmailValidatorTest < ActiveSupport::TestCase
  test ".disposable? returns true for known disposable domains" do
    assert_equal true, DisposableEmailValidator.disposable?("test@mailinator.com")
    assert_equal true, DisposableEmailValidator.disposable?("test@guerrillamail.com")
  end

  test ".disposable? returns false for legitimate domains" do
    assert_equal false, DisposableEmailValidator.disposable?("test@gmail.com")
    assert_equal false, DisposableEmailValidator.disposable?("test@example.com")
  end

  test ".disposable? returns false for blank input" do
    assert_equal false, DisposableEmailValidator.disposable?("")
    assert_equal false, DisposableEmailValidator.disposable?(nil)
  end

  test ".disposable? is case-insensitive" do
    assert_equal true, DisposableEmailValidator.disposable?("test@MAILINATOR.COM")
  end

  class UserSignupValidationTest < ActiveSupport::TestCase
    setup do
      Feature.activate(:block_disposable_emails_at_signup)
    end

    teardown do
      Feature.deactivate(:block_disposable_emails_at_signup)
    end

    test "blocks signup with a disposable email domain" do
      user = User.new(email: "test@mailinator.com")
      user.valid?(:create)
      assert_includes user.errors[:email], "is from a disposable email provider and cannot be used"
    end

    test "allows signup with a legitimate email domain" do
      user = User.new(email: "test@example.com")
      user.valid?(:create)
      assert_empty user.errors[:email]
    end

    test "skips the validation when the feature flag is disabled" do
      Feature.deactivate(:block_disposable_emails_at_signup)
      user = User.new(email: "test@mailinator.com")
      user.valid?(:create)
      assert_empty user.errors[:email]
    end
  end
end
