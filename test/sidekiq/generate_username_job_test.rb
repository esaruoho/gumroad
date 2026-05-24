# frozen_string_literal: true

require "test_helper"

class GenerateUsernameJobTest < ActiveSupport::TestCase
  test "does not generate a new username when username is present" do
    user = users(:referrer_user)
    assert user.read_attribute(:username).present?

    called = false
    UsernameGeneratorService.stub(:new, ->(*_) { called = true; raise "should not be called" }) do
      GenerateUsernameJob.new.perform(user.id)
    end
    refute called
  end

  test "generates a new username when username is blank" do
    user = users(:url_service_user_no_username)
    assert_nil user.read_attribute(:username)

    fake_service = Object.new
    fake_service.define_singleton_method(:username) { "foo" }

    UsernameGeneratorService.stub(:new, ->(_) { fake_service }) do
      GenerateUsernameJob.new.perform(user.id)
    end

    assert_equal "foo", user.reload.username
  end
end
