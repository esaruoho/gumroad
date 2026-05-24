# frozen_string_literal: true

require "test_helper"

class RescueSmtpErrorsTest < ActionMailer::TestCase
  class TestMailer < ActionMailer::Base
    include RescueSmtpErrors

    def welcome
      mail(from: "foo@bar.com", body: "")
    end
  end

  def with_welcome_raising(error)
    original = TestMailer.instance_method(:welcome)
    TestMailer.send(:define_method, :welcome) { raise error }
    yield
  ensure
    TestMailer.send(:define_method, :welcome, original)
  end

  test "raises ArgumentError messages other than blank-to-address" do
    with_welcome_raising(ArgumentError.new("something else")) do
      assert_raises(ArgumentError) { TestMailer.welcome.deliver_now }
    end
  end

  test "does not raise on blank smtp to address" do
    with_welcome_raising(ArgumentError.new("SMTP To address may not be blank")) do
      TestMailer.welcome.deliver_now
    end
  end

  test "does not raise Net::SMTPSyntaxError" do
    with_welcome_raising(Net::SMTPSyntaxError.new(nil)) do
      TestMailer.welcome.deliver_now
    end
  end

  test "does not raise Net::SMTPAuthenticationError" do
    with_welcome_raising(Net::SMTPAuthenticationError.new(nil)) do
      TestMailer.welcome.deliver_now
    end
  end
end
