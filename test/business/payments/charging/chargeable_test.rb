# frozen_string_literal: true

require "test_helper"

class BusinessPaymentsChargingChargeableTest < ActiveSupport::TestCase
  # Lightweight stand-in for an internal chargeable. Plays the role
  # RSpec's `double(charge_processor_id: "stripe")` did, but pure Ruby
  # so we don't need rspec-mocks.
  class FakeInternalChargeable
    attr_reader :charge_processor_id, :calls

    def initialize(charge_processor_id:, returns: {})
      @charge_processor_id = charge_processor_id
      @returns = returns
      @calls = Hash.new(0)
    end

    %i[prepare! fingerprint funding_type last4 number_length visual
       expiry_month expiry_year zip_code card_type country payment_method_id].each do |m|
      define_method(m) do
        @calls[m] += 1
        @returns.fetch(m)
      end
    end

    def reusable_token!(user)
      @calls[:reusable_token!] += 1
      @last_user = user
      @returns.fetch(:reusable_token!)
    end

    def last_reusable_token_user = @last_user
  end

  setup do
    @c1 = FakeInternalChargeable.new(
      charge_processor_id: "stripe",
      returns: {
        prepare!: true, fingerprint: "a-fingerprint", funding_type: "credit",
        last4: "4242", number_length: 16, visual: "**** **** **** 4242",
        expiry_month: 12, expiry_year: 2014, zip_code: "12345",
        card_type: "visa", country: "US", payment_method_id: "pm_123456",
        reusable_token!: "a-reusable-token-1"
      }
    )
    @c2 = FakeInternalChargeable.new(
      charge_processor_id: "braintree",
      returns: { reusable_token!: "a-reusable-token-2" }
    )
    @chargeable = Chargeable.new([@c1, @c2])
  end

  test "#charge_processor_ids returns all internal chargeable processor ids" do
    assert_equal %w[stripe braintree], @chargeable.charge_processor_ids
  end

  test "#charge_processor_id returns comma-joined combination" do
    assert_equal "stripe,braintree", @chargeable.charge_processor_id
  end

  test "#prepare! delegates to first chargeable only" do
    assert_equal true, @chargeable.prepare!
    assert_equal 1, @c1.calls[:prepare!]
    assert_equal 0, @c2.calls[:prepare!]
  end

  test "#fingerprint delegates to first chargeable only" do
    assert_equal "a-fingerprint", @chargeable.fingerprint
    assert_equal 1, @c1.calls[:fingerprint]
    assert_equal 0, @c2.calls[:fingerprint]
  end

  test "#last4 delegates to first chargeable only" do
    assert_equal "4242", @chargeable.last4
    assert_equal 0, @c2.calls[:last4]
  end

  test "#number_length delegates to first chargeable only" do
    assert_equal 16, @chargeable.number_length
  end

  test "#visual delegates to first chargeable only" do
    assert_equal "**** **** **** 4242", @chargeable.visual
  end

  test "#expiry_month delegates to first chargeable only" do
    assert_equal 12, @chargeable.expiry_month
  end

  test "#expiry_year delegates to first chargeable only" do
    assert_equal 2014, @chargeable.expiry_year
  end

  test "#zip_code delegates to first chargeable only" do
    assert_equal "12345", @chargeable.zip_code
  end

  test "#card_type delegates to first chargeable only" do
    assert_equal "visa", @chargeable.card_type
  end

  test "#country delegates to first chargeable only" do
    assert_equal "US", @chargeable.country
  end

  test "#payment_method_id delegates to first chargeable" do
    assert_equal "pm_123456", @chargeable.payment_method_id
  end

  test "#reusable_token_for! returns matching chargeable's token (stripe)" do
    user = users(:basic_user)
    assert_equal "a-reusable-token-1", @chargeable.reusable_token_for!("stripe", user)
    assert_equal user, @c1.last_reusable_token_user
    assert_equal 0, @c2.calls[:reusable_token!]
  end

  test "#reusable_token_for! returns matching chargeable's token (braintree)" do
    user = users(:basic_user)
    assert_equal "a-reusable-token-2", @chargeable.reusable_token_for!("braintree", user)
    assert_equal user, @c2.last_reusable_token_user
    assert_equal 0, @c1.calls[:reusable_token!]
  end

  test "#reusable_token_for! returns nil when no chargeable matches" do
    user = users(:basic_user)
    assert_nil @chargeable.reusable_token_for!("something-else", user)
    assert_equal 0, @c1.calls[:reusable_token!]
    assert_equal 0, @c2.calls[:reusable_token!]
  end

  test "#get_chargeable_for returns matching underlying chargeable" do
    assert_equal @c1, @chargeable.get_chargeable_for("stripe")
    assert_equal @c2, @chargeable.get_chargeable_for("braintree")
  end

  test "#get_chargeable_for returns nil when not available" do
    assert_nil @chargeable.get_chargeable_for("something-else")
  end

  test "#stripe_payment_intent_id returns nil for non-Stripe chargeable" do
    paypal = Chargeable.new([
      PaypalChargeable.new("B-test", "buyer@example.com", "US")
    ])
    assert_nil paypal.stripe_payment_intent_id
  end

  test "#stripe_setup_intent_id returns nil for non-Stripe chargeable" do
    paypal = Chargeable.new([
      PaypalChargeable.new("B-test", "buyer@example.com", "US")
    ])
    assert_nil paypal.stripe_setup_intent_id
  end

  test "#requires_mandate? returns false for non-Stripe (paypal) chargeable" do
    paypal = Chargeable.new([
      PaypalChargeable.new("B-test", "buyer@example.com", "US")
    ])
    assert_equal false, paypal.requires_mandate?
  end

  test "#can_be_saved? returns false if underlying chargeable is PaypalApprovedOrderChargeable" do
    chargeable = Chargeable.new([
      PaypalApprovedOrderChargeable.new("9XX680320L106570A", "buyer@example.com", "US")
    ])
    assert_equal PaypalChargeProcessor.charge_processor_id, chargeable.charge_processor_id
    assert_instance_of PaypalApprovedOrderChargeable,
      chargeable.get_chargeable_for(chargeable.charge_processor_id)
    assert_equal false, chargeable.can_be_saved?
  end

  test "#can_be_saved? returns true if underlying chargeable is PaypalChargeable" do
    chargeable = Chargeable.new([
      PaypalChargeable.new("B-8AM85704X2276171X", "buyer@example.com", "US")
    ])
    assert_equal PaypalChargeProcessor.charge_processor_id, chargeable.charge_processor_id
    assert_instance_of PaypalChargeable,
      chargeable.get_chargeable_for(chargeable.charge_processor_id)
    assert_equal true, chargeable.can_be_saved?
  end
end
