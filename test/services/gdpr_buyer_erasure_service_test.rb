# frozen_string_literal: true

require "test_helper"

class GdprBuyerErasureServiceTest < ActiveSupport::TestCase
  test "anonymized constants inherit from GdprDataErasureService" do
    assert_equal GdprDataErasureService::ANONYMIZED_EMAIL_DOMAIN, GdprBuyerErasureService::ANONYMIZED_EMAIL_DOMAIN
    assert_equal GdprDataErasureService::ANONYMIZED_NAME, GdprBuyerErasureService::ANONYMIZED_NAME
    assert_equal GdprDataErasureService::ANONYMIZED_VALUE, GdprBuyerErasureService::ANONYMIZED_VALUE
  end

  test "initializer normalizes email to lowercase + stripped form and tracks performed_by" do
    actor = users(:named_seller)
    service = GdprBuyerErasureService.new("  Buyer@Example.COM ", performed_by: actor)

    assert_equal "buyer@example.com", service.email
    assert_equal actor, service.performed_by
    assert_kind_of Hash, service.counts
    # Hash defaults to 0 so callers can ++ without nil checks
    assert_equal 0, service.counts[:any_unknown_key]
  end

  test "perform! raises ArgumentError when email is blank" do
    service = GdprBuyerErasureService.new("   ", performed_by: users(:named_seller))

    assert_raises(ArgumentError) { service.perform! }
  end

  test "perform! raises ArgumentError when the email belongs to a User (account holder)" do
    actor = users(:named_seller)
    service = GdprBuyerErasureService.new(users(:basic_user).email, performed_by: actor)

    error = assert_raises(ArgumentError) { service.perform! }
    assert_match(/Use GdprDataErasureService for account holders/, error.message)
  end

  # TODO: full buyer erasure flow (16 FactoryBot refs) sweeps purchases,
  # refunds, comments, subscriptions, followers, audience_members + sends a
  # confirmation mail. That requires a multi-table buyer fixture web that
  # is not yet on the migration branch. Original:
  # spec/services/gdpr_buyer_erasure_service_spec.rb
end
