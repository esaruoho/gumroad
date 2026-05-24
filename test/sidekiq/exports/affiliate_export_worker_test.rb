# frozen_string_literal: true

require "test_helper"

class Exports::AffiliateExportWorkerTest < ActiveSupport::TestCase
  setup do
    @seller = users(:basic_user)
    @recipient = users(:purchaser)
    ActionMailer::Base.deliveries.clear

    @fake_result = Struct.new(:tempfile, :filename).new(
      Tempfile.new(["affiliates-test", ".csv"]), "affiliates-test.csv"
    )
    fake_result = @fake_result
    @fake_service = Object.new
    @fake_service.define_singleton_method(:perform) { fake_result }

    fake_service = @fake_service
    @orig_service_new = Exports::AffiliateExportService.method(:new)
    Exports::AffiliateExportService.define_singleton_method(:new) do |*_args|
      fake_service
    end

    @mailer_calls = []
    recorded = @mailer_calls
    ContactingCreatorMailer.singleton_class.send(:define_method, :affiliates_data) do |**kwargs|
      recorded << kwargs
      md = Object.new
      md.define_singleton_method(:deliver_now) { Mail.new(to: kwargs[:recipient].email) }
      md
    end
  end

  teardown do
    Exports::AffiliateExportService.define_singleton_method(:new, @orig_service_new) if @orig_service_new
    if ContactingCreatorMailer.singleton_class.method_defined?(:affiliates_data) ||
       ContactingCreatorMailer.singleton_class.private_method_defined?(:affiliates_data)
      ContactingCreatorMailer.singleton_class.send(:remove_method, :affiliates_data)
    end
    @fake_result.tempfile.close! rescue nil
  end

  test "invokes ContactingCreatorMailer.affiliates_data with the seller as recipient when no recipient given" do
    Exports::AffiliateExportWorker.new.perform(@seller.id, @seller.id)

    assert_equal 1, @mailer_calls.length
    assert_equal @seller, @mailer_calls.first[:recipient]
    assert_equal "affiliates-test.csv", @mailer_calls.first[:filename]
  end

  test "invokes ContactingCreatorMailer.affiliates_data with the given recipient" do
    Exports::AffiliateExportWorker.new.perform(@seller.id, @recipient.id)

    assert_equal 1, @mailer_calls.length
    assert_equal @recipient, @mailer_calls.first[:recipient]
  end
end
