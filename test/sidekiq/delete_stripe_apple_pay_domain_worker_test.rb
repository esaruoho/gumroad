# frozen_string_literal: true

require "test_helper"

class DeleteStripeApplePayDomainWorkerTest < ActiveSupport::TestCase
  setup do
    @user = users(:basic_user)
  end

  test "no-ops when no matching StripeApplePayDomain record exists" do
    called = false
    Stripe::ApplePayDomain.stub(:delete, ->(_id) { called = true; nil }) do
      DeleteStripeApplePayDomainWorker.new.perform(@user.id, "missing.example.com")
    end
    refute called
  end

  test "deletes the record after a successful Stripe::ApplePayDomain.delete" do
    record = StripeApplePayDomain.create!(user: @user, domain: "example.com",
                                           stripe_id: "apwc_#{SecureRandom.hex(6)}")
    response = Struct.new(:deleted).new(true)
    Stripe::ApplePayDomain.stub(:delete, ->(stripe_id) {
      assert_equal record.stripe_id, stripe_id
      response
    }) do
      DeleteStripeApplePayDomainWorker.new.perform(@user.id, "example.com")
    end
    assert_nil StripeApplePayDomain.find_by(id: record.id)
  end

  test "keeps record if Stripe responds with deleted=false" do
    record = StripeApplePayDomain.create!(user: @user, domain: "kept.example.com",
                                           stripe_id: "apwc_#{SecureRandom.hex(6)}")
    response = Struct.new(:deleted).new(false)
    Stripe::ApplePayDomain.stub(:delete, ->(_id) { response }) do
      DeleteStripeApplePayDomainWorker.new.perform(@user.id, "kept.example.com")
    end
    assert StripeApplePayDomain.exists?(record.id)
  end

  test "destroys record when Stripe raises InvalidRequestError" do
    record = StripeApplePayDomain.create!(user: @user, domain: "stale.example.com",
                                           stripe_id: "apwc_stale")
    Stripe::ApplePayDomain.stub(:delete, ->(_id) {
      raise Stripe::InvalidRequestError.new("no such apple_pay_domain", nil)
    }) do
      DeleteStripeApplePayDomainWorker.new.perform(@user.id, "stale.example.com")
    end
    assert_nil StripeApplePayDomain.find_by(id: record.id)
  end
end
