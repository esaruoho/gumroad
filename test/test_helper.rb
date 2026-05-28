# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock" # Object#stub for instance stubbing
require "shoulda/matchers"
require "webmock/minitest"

WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: %w[
    minio
    s3.amazonaws.com
    gumroad-specs.s3.amazonaws.com
    elasticsearch
    redis
    mongo
  ]
)


Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end

module ActiveSupport
  class TestCase
    # Disabled until per-worker Redis isolation is set up — Flipper feature flag state
    # lives in shared Redis and races between workers.
    # parallelize(workers: :number_of_processors)

    fixtures :all

    include ActiveSupport::Testing::TimeHelpers
    include Shoulda::Matchers::ActiveModel
    include Shoulda::Matchers::ActiveRecord

    setup do
      # devise_pwned_password hits api.pwnedpasswords.com on every save.
      # Stub it inside setup so the registration survives WebMock.reset! between tests.
      WebMock.stub_request(:get, %r{\Ahttps://api\.pwnedpasswords\.com/range/}).to_return(status: 200, body: "")

      # Mirror spec_helper.rb's before(:each): flush sidekiq+redis, activate baseline feature flags.
      Sidekiq.redis(&:flushdb)
      $redis.flushdb
      %i[
        store_discover_searches
        log_email_events
        follow_wishlists
        seller_refund_policy_new_users_enabled
        paypal_payout_fee
        disable_braintree_sales
      ].each { |feature| Feature.activate(feature) }
    end

    def assert_invalid(record, attribute = nil)
      refute record.valid?, "Expected #{record.class} to be invalid"
      assert record.errors[attribute].any?, "Expected error on #{attribute}" if attribute
    end

    def assert_valid(record)
      assert record.valid?, "Expected valid, got errors: #{record.errors.full_messages.to_sentence}"
    end

    # Save a constant, run the block with a new value, restore the original.
    # Replacement for RSpec's stub_const.
    def with_constant(name, value, scope: Object)
      had = scope.const_defined?(name, false)
      original = scope.const_get(name) if had
      scope.send(:remove_const, name) if had
      scope.const_set(name, value)
      yield
    ensure
      scope.send(:remove_const, name)
      scope.const_set(name, original) if had
    end

    def new_user(**attrs)
      defaults = {
        email: "u-#{SecureRandom.hex(6)}@example.com",
        username: "u#{SecureRandom.hex(4)}",
        password: "password",
        password_confirmation: "password",
        confirmed_at: Time.current,
        user_risk_state: "not_reviewed",
        skip_enabling_two_factor_authentication: true,
      }
      User.new(defaults.merge(attrs))
    end

    def create_user(**attrs)
      new_user(**attrs).tap(&:save!)
    end
  end
end
