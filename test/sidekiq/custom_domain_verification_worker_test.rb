# frozen_string_literal: true

require "test_helper"

class CustomDomainVerificationWorkerTest < ActiveSupport::TestCase
  test "marks a valid custom domain as verified" do
    domain = custom_domains(:cdvw_unverified_one)
    service = Minitest::Mock.new
    service.expect(:process, true)

    CustomDomainVerificationService.stub(:new, ->(**kwargs) { assert_equal domain.domain, kwargs[:domain]; service }) do
      assert_changes -> { domain.reload.verified? }, from: false, to: true do
        CustomDomainVerificationWorker.new.perform(domain.id)
      end
    end
  end

  test "increments failed verification attempts when invalid" do
    domain = custom_domains(:cdvw_under_limit)
    service = Minitest::Mock.new
    service.expect(:process, false)

    CustomDomainVerificationService.stub(:new, ->(**) { service }) do
      assert_no_changes -> { domain.reload.verified? } do
        assert_changes -> { domain.reload.failed_verification_attempts_count }, from: 2, to: 3 do
          CustomDomainVerificationWorker.new.perform(domain.id)
        end
      end
    end
  end

  test "ignores verification of a deleted custom domain" do
    domain = custom_domains(:cdvw_deleted)
    called = false
    CustomDomainVerificationService.stub(:new, ->(**) { called = true; raise "should not be called" }) do
      CustomDomainVerificationWorker.new.perform(domain.id)
    end
    refute called
  end

  test "ignores verification of a custom domain with an invalid hostname" do
    domain = CustomDomain.new(
      user_id: users(:named_seller).id,
      domain: "invalid_domain_name.test",
    )
    domain.save(validate: false)

    called = false
    CustomDomainVerificationService.stub(:new, ->(**) { called = true; raise "should not be called" }) do
      CustomDomainVerificationWorker.new.perform(domain.id)
    end
    refute called
  end
end
