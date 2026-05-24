# frozen_string_literal: true

require "test_helper"
require "benchmark"

class Admin::RelatedUsersServiceBenchmarkTest < ActiveSupport::TestCase
  test "related-users lookup runs under 500ms with realistic fan-out" do
    skip "Run with RUN_RELATED_USERS_BENCHMARK=1" unless ENV["RUN_RELATED_USERS_BENCHMARK"] == "1"

    target = create_user!(
      account_created_ip: "1.2.3.4",
      current_sign_in_ip: "5.6.7.8",
      last_sign_in_ip: nil,
      payment_address: "benchmark-payment@example.com",
      credit_card: credit_card_with_fingerprint("fp_benchmark")
    )

    200.times do |index|
      create_user!(
        account_created_ip: "198.51.100.#{index % 250}",
        current_sign_in_ip: nil,
        last_sign_in_ip: nil,
        payment_address: "unrelated-#{index}@example.com"
      )
    end

    200.times do |index|
      create_user!(
        email: "benchmark-ip-#{index}@example.com",
        account_created_ip: "1.2.3.4",
        current_sign_in_ip: nil,
        last_sign_in_ip: nil,
        payment_address: nil
      )
    end

    200.times do |index|
      create_user!(
        email: "benchmark-payment-#{index}@example.com",
        account_created_ip: nil,
        current_sign_in_ip: nil,
        last_sign_in_ip: nil,
        payment_address: "benchmark-payment@example.com"
      )
    end

    200.times do |index|
      create_user!(
        email: "benchmark-card-#{index}@example.com",
        account_created_ip: nil,
        current_sign_in_ip: nil,
        last_sign_in_ip: nil,
        payment_address: nil,
        credit_card: credit_card_with_fingerprint("fp_benchmark")
      )
    end

    Admin::RelatedUsersService.new(target).call
    duration = Benchmark.realtime { Admin::RelatedUsersService.new(target).call }
    puts "Related users benchmark: #{(duration * 1000).round(1)}ms"

    assert_operator duration, :<, 0.5
  end

  private
    def credit_card_with_fingerprint(fingerprint)
      CreditCard.create!(
        stripe_fingerprint: fingerprint,
        visual: "**** **** **** 4242",
        card_type: CardType::VISA,
        stripe_customer_id: "cus_#{SecureRandom.hex(6)}",
        expiry_month: 12,
        expiry_year: 2030,
        charge_processor_id: StripeChargeProcessor.charge_processor_id
      )
    end

    def create_user!(attributes)
      User.create!(
        {
          email: "benchmark-#{SecureRandom.hex(8)}@example.com",
          password: "test-password-123!",
          confirmed_at: Time.current,
          user_risk_state: "not_reviewed",
          recommendation_type: User::RecommendationType::OWN_PRODUCTS,
          created_at: Time.current,
          updated_at: Time.current,
        }.merge(attributes)
      )
    end
end
