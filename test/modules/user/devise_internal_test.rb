# frozen_string_literal: true

require "test_helper"

class User::DeviseInternalTest < ActiveSupport::TestCase
  setup do
    @user = users(:unconfirmed_user)
  end

  test "#confirmation_required? returns true if email is required" do
    @user.define_singleton_method(:email_required?) { true }
    @user.define_singleton_method(:platform_user?) { false }
    assert_equal true, @user.confirmation_required?
  end

  test "#confirmation_required? returns false if email is not required" do
    @user.define_singleton_method(:email_required?) { false }
    assert_equal false, @user.confirmation_required?
  end
end
