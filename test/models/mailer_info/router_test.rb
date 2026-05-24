# frozen_string_literal: true

require "test_helper"

class MailerInfo::RouterTest < ActiveSupport::TestCase
  setup do
    @domain = :gumroad
    @date = Date.current
  end

  teardown do
    # Clean redis keys created in tests
    [@date, @date.to_s].uniq.each do |d|
      $redis.del("mail_router:counter:#{@domain}:#{d}")
      $redis.del("mail_router:max_count:#{@domain}:#{d}")
      $redis.del("mail_router:probability:#{@domain}:#{d}")
    end
    Feature.deactivate(:resend) if Feature.active?(:resend)
  end

  test ".determine_email_provider raises error for invalid domain" do
    error = assert_raises(ArgumentError) { MailerInfo::Router.determine_email_provider(:invalid) }
    assert_equal "Invalid domain: invalid", error.message
  end

  test ".determine_email_provider returns SendGrid in test environment" do
    assert_equal MailerInfo::EMAIL_PROVIDER_SENDGRID, MailerInfo::Router.determine_email_provider(@domain)
  end

  test ".determine_email_provider returns SendGrid when resend active without counts" do
    Rails.env.stub(:test?, false) do
      Feature.activate(:resend)
      assert_equal MailerInfo::EMAIL_PROVIDER_SENDGRID, MailerInfo::Router.determine_email_provider(@domain)
    end
  end

  test ".determine_email_provider returns SendGrid when max count is reached" do
    Rails.env.stub(:test?, false) do
      Feature.activate(:resend)
      MailerInfo::Router.set_max_count(@domain, @date, 10)
      $redis.set(MailerInfo::Router.send(:current_count_key, @domain, date: @date), 10)
      assert_equal MailerInfo::EMAIL_PROVIDER_SENDGRID, MailerInfo::Router.determine_email_provider(@domain)
    end
  end

  test ".determine_email_provider returns Resend based on probability" do
    Rails.env.stub(:test?, false) do
      Feature.activate(:resend)
      MailerInfo::Router.set_probability(@domain, @date, 1.0)
      MailerInfo::Router.set_max_count(@domain, @date, 100)
      $redis.set(MailerInfo::Router.send(:current_count_key, @domain, date: @date), 0)
      Kernel.stub(:rand, 0.5) do
        assert_equal MailerInfo::EMAIL_PROVIDER_RESEND, MailerInfo::Router.determine_email_provider(@domain)
      end
    end
  end

  test ".determine_email_provider returns SendGrid based on probability" do
    Rails.env.stub(:test?, false) do
      Feature.activate(:resend)
      MailerInfo::Router.set_probability(@domain, @date, 0.0)
      MailerInfo::Router.set_max_count(@domain, @date, 100)
      $redis.set(MailerInfo::Router.send(:current_count_key, @domain, date: @date), 0)
      Kernel.stub(:rand, 0.5) do
        assert_equal MailerInfo::EMAIL_PROVIDER_SENDGRID, MailerInfo::Router.determine_email_provider(@domain)
      end
    end
  end

  test ".determine_email_provider increments counter when choosing Resend" do
    Rails.env.stub(:test?, false) do
      Feature.activate(:resend)
      MailerInfo::Router.set_probability(@domain, @date, 1.0)
      MailerInfo::Router.set_max_count(@domain, @date, 100)
      key = MailerInfo::Router.send(:current_count_key, @domain, date: @date)
      $redis.set(key, 0)
      Kernel.stub(:rand, 0.5) do
        before = $redis.get(key).to_i
        MailerInfo::Router.determine_email_provider(@domain)
        assert_equal before + 1, $redis.get(key).to_i
      end
    end
  end

  test ".set_probability raises error for invalid domain" do
    error = assert_raises(ArgumentError) { MailerInfo::Router.set_probability(:invalid, @date, 0.5) }
    assert_equal "Invalid domain: invalid", error.message
  end

  test ".set_probability sets probability in Redis" do
    MailerInfo::Router.set_probability(@domain, @date, 0.5)
    key = MailerInfo::Router.send(:probability_key, @domain, date: @date)
    assert_equal 0.5, $redis.get(key).to_f
  end

  test ".set_max_count raises error for invalid domain" do
    error = assert_raises(ArgumentError) { MailerInfo::Router.set_max_count(:invalid, @date, 100) }
    assert_equal "Invalid domain: invalid", error.message
  end

  test ".set_max_count sets max count in Redis" do
    MailerInfo::Router.set_max_count(@domain, @date, 100)
    key = MailerInfo::Router.send(:max_count_key, @domain, date: @date)
    assert_equal 100, $redis.get(key).to_i
  end

  test ".domain_stats raises error for invalid domain" do
    error = assert_raises(ArgumentError) { MailerInfo::Router.domain_stats(:invalid) }
    assert_equal "Invalid domain: invalid", error.message
  end

  test ".domain_stats returns stats for domain" do
    MailerInfo::Router.set_probability(@domain, @date, 0.5)
    MailerInfo::Router.set_max_count(@domain, @date, 100)
    $redis.set(MailerInfo::Router.send(:current_count_key, @domain), 42)

    stats = MailerInfo::Router.domain_stats(@domain)
    match = stats.find { |s| s[:date] == @date.to_s }
    assert match, "expected stats to include today's date"
    assert_equal 0.5, match[:probability]
    assert_equal 100, match[:max_count]
    assert_equal 42, match[:current_count]
  end

  test ".stats returns stats for all domains" do
    MailerInfo::Router.set_probability(:gumroad, @date, 0.5)
    MailerInfo::Router.set_max_count(:gumroad, @date, 100)

    stats = MailerInfo::Router.stats
    assert_equal MailerInfo::DeliveryMethod::DOMAINS.sort, stats.keys.sort
    assert stats[:gumroad].present?
  end
end
