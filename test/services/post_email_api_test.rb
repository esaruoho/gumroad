# frozen_string_literal: true

require "test_helper"

class PostEmailApiTest < ActiveSupport::TestCase
  setup do
    @seller = users(:named_seller)
    @post = installments(:published_post)
    @recipients = 10.times.map { |i| { email: "recipient#{i}@gumroad-example.com" } }
    @args = { post: @post, recipients: @recipients }
  end

  test ".process splits recipients between Resend and SendGrid when feature flag active" do
    Feature.stub(:inactive?, ->(flag, seller) { false }) do
      call_count = 0
      router = Class.new do
        define_singleton_method(:determine_email_provider) do |_domain|
          call_count += 1
          call_count <= 4 ? MailerInfo::EMAIL_PROVIDER_RESEND : MailerInfo::EMAIL_PROVIDER_SENDGRID
        end
      end
      MailerInfo::Router.stub(:determine_email_provider, ->(domain) { router.determine_email_provider(domain) }) do
        resend_recipients = @recipients[0..3]
        sendgrid_recipients = @recipients[4..9]

        resend_calls = []
        sendgrid_calls = []
        PostResendApi.stub(:process, ->(**kw) { resend_calls << kw }) do
          PostSendgridApi.stub(:process, ->(**kw) { sendgrid_calls << kw }) do
            PostEmailApi.process(**@args)
          end
        end
        assert_equal [{ post: @post, recipients: resend_recipients }], resend_calls
        assert_equal [{ post: @post, recipients: sendgrid_recipients }], sendgrid_calls
      end
    end
  end

  def assert_routes_to_sendgrid(non_resend_args)
    Feature.stub(:inactive?, ->(flag, seller) { false }) do
      MailerInfo::Router.stub(:determine_email_provider, MailerInfo::EMAIL_PROVIDER_RESEND) do
        sendgrid_calls = []
        resend_calls = []
        PostSendgridApi.stub(:process, ->(**kw) { sendgrid_calls << kw }) do
          PostResendApi.stub(:process, ->(**kw) { resend_calls << kw }) do
            PostEmailApi.process(**non_resend_args)
          end
        end
        assert_equal [non_resend_args], sendgrid_calls
        assert_empty resend_calls
      end
    end
  end

  test ".process routes non-ASCII emails through SendGrid" do
    assert_routes_to_sendgrid(post: @post, recipients: [{ email: "récipient@gumroad-example.com" }])
  end

  test ".process routes emails with local parts exceeding 64 characters through SendGrid" do
    long_local_part = "a" * 65
    assert_routes_to_sendgrid(post: @post, recipients: [{ email: "#{long_local_part}@gumroad-example.com" }])
  end

  test ".process routes emails with special characters through SendGrid" do
    special_char_emails = [
      "recipient!@gumroad-example.com",
      "recipient*@gumroad-example.com",
      "recipient=@gumroad-example.com",
      "recipient$@gumroad-example.com",
      "recipient{@gumroad-example.com",
      "recipient-name@gumroad-example.com",
    ]
    special_char_emails.each do |email|
      assert_routes_to_sendgrid(post: @post, recipients: [{ email: email }])
    end
  end

  test ".process routes emails with formatting issues through SendGrid" do
    invalid_format_emails = [
      "", nil,
      "userexample.com",
      "user@example@domain.com",
      "@gumroad-example.com",
      "user@",
      "user@gumroad-example",
      "user@.gumroad-example.com",
      "user@gumroad-example.com.",
    ]
    invalid_format_emails.each do |email|
      assert_routes_to_sendgrid(post: @post, recipients: [{ email: email }])
    end
  end

  test ".process routes emails from excluded domains through SendGrid" do
    %w[example.com example.org example.net test.com].each do |domain|
      assert_routes_to_sendgrid(post: @post, recipients: [{ email: "user@#{domain}" }])
    end
  end

  test ".process routes emails exceeding maximum length through SendGrid" do
    long_local_part = "a" * 245
    assert_routes_to_sendgrid(post: @post, recipients: [{ email: "#{long_local_part}@gumroad-example.com" }])
  end

  test ".process routes valid emails through Resend when determined by the router" do
    Feature.stub(:inactive?, ->(flag, seller) { false }) do
      MailerInfo::Router.stub(:determine_email_provider, MailerInfo::EMAIL_PROVIDER_RESEND) do
        valid_args = { post: @post, recipients: [{ email: "user.name+tag@gumroad-example.com" }] }
        resend_calls = []
        sendgrid_calls = []
        PostResendApi.stub(:process, ->(**kw) { resend_calls << kw }) do
          PostSendgridApi.stub(:process, ->(**kw) { sendgrid_calls << kw }) do
            PostEmailApi.process(**valid_args)
          end
        end
        assert_equal [valid_args], resend_calls
        assert_empty sendgrid_calls
      end
    end
  end

  test ".process routes valid emails through SendGrid when determined by the router" do
    Feature.stub(:inactive?, ->(flag, seller) { false }) do
      MailerInfo::Router.stub(:determine_email_provider, MailerInfo::EMAIL_PROVIDER_SENDGRID) do
        valid_args = { post: @post, recipients: [{ email: "user_name_123@gumroad-example.com" }] }
        resend_calls = []
        sendgrid_calls = []
        PostResendApi.stub(:process, ->(**kw) { resend_calls << kw }) do
          PostSendgridApi.stub(:process, ->(**kw) { sendgrid_calls << kw }) do
            PostEmailApi.process(**valid_args)
          end
        end
        assert_equal [valid_args], sendgrid_calls
        assert_empty resend_calls
      end
    end
  end

  test ".process sends all emails through SendGrid when feature flag inactive" do
    Feature.stub(:inactive?, ->(flag, seller) { true }) do
      sendgrid_calls = []
      PostSendgridApi.stub(:process, ->(**kw) { sendgrid_calls << kw }) do
        PostEmailApi.process(**@args)
      end
      assert_equal [@args], sendgrid_calls
    end
  end

  test ".max_recipients returns the Resend max recipients when feature flag active" do
    Feature.stub(:active?, ->(flag) { true }) do
      assert_equal PostResendApi::MAX_RECIPIENTS, PostEmailApi.max_recipients
    end
  end

  test ".max_recipients returns the SendGrid max recipients when feature flag inactive" do
    Feature.stub(:active?, ->(flag) { false }) do
      assert_equal PostSendgridApi::MAX_RECIPIENTS, PostEmailApi.max_recipients
    end
  end
end
