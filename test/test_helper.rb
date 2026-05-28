# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock" # Object#stub for instance stubbing
require "shoulda/matchers"
require "webmock/minitest"
require "sidekiq/testing"

Sidekiq::Testing.fake!

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
      # ProductRefundPolicy content moderation hits OpenAI. Stub to default "false".
      WebMock.stub_request(:post, "https://api.openai.com/v1/chat/completions").to_return(
        status: 200,
        body: { choices: [{ message: { content: '{"no_refunds": false}' } }] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

      # Mirror spec_helper.rb's before(:each): flush sidekiq+redis, activate baseline feature flags.
      Sidekiq.redis(&:flushdb)
      $redis.flushdb
      Sidekiq::Worker.clear_all
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

    # Build & save a minimal valid Link (Product). Link requires user, name,
    # default_price_cents, unique_permalink (auto-generated if not set, but the
    # validation runs on the model so we set explicitly).
    def create_link(user, name: "Test Product", **attrs)
      Link.create!(
        user: user,
        name: name,
        unique_permalink: SecureRandom.alphanumeric(8).gsub(/[^a-zA-Z_]/, "a"),
        price_cents: 100,
        **attrs
      )
    end

    # Build a Balance. Balance requires currency, holding_currency, merchant_account.
    def create_balance(user:, merchant_account: nil, **attrs)
      merchant_account ||= create_merchant_account(user: user)
      Balance.create!(
        user: user,
        merchant_account: merchant_account,
        currency: "usd",
        holding_currency: "usd",
        date: Date.current,
        **attrs
      )
    end

    # MerchantAccount must have charge_processor_alive_at set or it won't be `alive`/
    # `charge_processor_alive` for any of the user.merchant_account lookups.
    def create_merchant_account(user:, charge_processor_id: "stripe", **attrs)
      MerchantAccount.create!(
        user: user,
        charge_processor_id: charge_processor_id,
        charge_processor_alive_at: Time.current,
        charge_processor_merchant_id: "cprmid_#{SecureRandom.hex(8)}",
        **attrs
      )
    end

    def create_stripe_connect_account(user:, country: "US", **attrs)
      create_merchant_account(
        user: user,
        country: country,
        json_data: { "meta" => { "stripe_connect" => "true" } },
        **attrs
      )
    end

    def create_paypal_merchant_account(user:, **attrs)
      create_merchant_account(
        user: user,
        charge_processor_id: "paypal",
        **attrs
      )
    end

    def create_payment_completed(user:, **attrs)
      Payment.create!(
        user: user,
        state: "completed",
        processor: PayoutProcessorType::PAYPAL,
        correlation_id: "12345",
        amount_cents: 150,
        payout_period_end_date: Date.yesterday,
        txn_id: "txn-id-#{SecureRandom.hex(4)}",
        processor_fee_cents: 10,
        **attrs
      )
    end

    def create_subscription_product(user:, **attrs)
      create_link(user, **{
        is_recurring_billing: true,
        subscription_duration: :monthly,
        is_tiered_membership: false,
      }.merge(attrs))
    end

    def create_membership_product(user:, **attrs)
      create_link(user, **{
        is_recurring_billing: true,
        subscription_duration: :monthly,
        is_tiered_membership: true,
        native_type: "membership",
      }.merge(attrs))
    end

    def create_user_compliance_info(user:, country: "United States", **attrs)
      UserComplianceInfo.create!(
        user: user,
        first_name: "Chuck",
        last_name: "Bartowski",
        street_address: "address_full_match",
        city: "San Francisco",
        state: "California",
        zip_code: "94107",
        country: country,
        verticals: [Vertical::PUBLISHING],
        is_business: false,
        has_sold_before: false,
        individual_tax_id: "000000000",
        birthday: Date.new(1901, 1, 1),
        dba: "Chuckster",
        phone: "0000000000",
        **attrs
      )
    end

    def create_purchase(seller:, link:, purchaser: nil, **attrs)
      attrs = {
        purchase_state: "successful",
        price_cents: 100,
        displayed_price_cents: 100,
        fee_cents: 0,
        total_transaction_cents: 100,
      }.merge(attrs)
      # If a merchant_account is provided, the Purchase model demands stripe_fingerprint +
      # charge_processor_id to be present together. Fill them in so the helper "just works".
      # Purchase has a financial_transaction_validation that requires either a
      # full {price>0, merchant_account, stripe_*, charge_processor_id} tuple or a
      # free purchase with no charge fields at all. Default to the paid-charge tuple.
      attrs[:merchant_account] ||= create_merchant_account(user: seller)
      attrs[:stripe_fingerprint] ||= "fp_#{SecureRandom.hex(8)}"
      attrs[:stripe_transaction_id] ||= "txn_#{SecureRandom.hex(8)}"
      attrs[:charge_processor_id] ||= attrs[:merchant_account].charge_processor_id
      Purchase.create!(
        seller: seller,
        link: link,
        purchaser: purchaser,
        email: purchaser&.email || "buyer-#{SecureRandom.hex(4)}@example.com",
        **attrs
      )
    end
  end
end
