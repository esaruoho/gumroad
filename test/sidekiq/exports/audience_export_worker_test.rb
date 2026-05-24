# frozen_string_literal: true

require "test_helper"

class Exports::AudienceExportWorkerTest < ActiveSupport::TestCase
  setup do
    @seller = users(:basic_user)
    @recipient = users(:purchaser)
    @audience_options = { followers: true }
    ActionMailer::Base.deliveries.clear

    @fake_result = Struct.new(:tempfile, :filename).new(
      Tempfile.new(["audience-test", ".csv"]), "audience-test.csv"
    )
    fake_result = @fake_result
    @fake_service = Object.new
    @fake_service.define_singleton_method(:perform) { fake_result }

    fake_service = @fake_service
    @orig_service_new = Exports::AudienceExportService.method(:new)
    Exports::AudienceExportService.define_singleton_method(:new) do |*_args|
      fake_service
    end

    # Record ContactingCreatorMailer.subscribers_data calls without delivering
    # the real email (avoids the heavy Premailer/view rendering pipeline).
    @mailer_calls = []
    recorded = @mailer_calls
    target = :subscribers_data
    ContactingCreatorMailer.singleton_class.send(:define_method, target) do |**kwargs|
      recorded << kwargs
      md = Object.new
      md.define_singleton_method(:deliver_now) { Mail.new(to: kwargs[:recipient].email) }
      md
    end
  end

  teardown do
    Exports::AudienceExportService.define_singleton_method(:new, @orig_service_new) if @orig_service_new
    if ContactingCreatorMailer.singleton_class.method_defined?(:subscribers_data) ||
       ContactingCreatorMailer.singleton_class.private_method_defined?(:subscribers_data)
      ContactingCreatorMailer.singleton_class.send(:remove_method, :subscribers_data)
    end
    @fake_result.tempfile.close! rescue nil
  end

  test "invokes ContactingCreatorMailer.subscribers_data with the seller as recipient when no recipient given" do
    Exports::AudienceExportWorker.new.perform(@seller.id, @seller.id, @audience_options)

    assert_equal 1, @mailer_calls.length
    assert_equal @seller, @mailer_calls.first[:recipient]
    assert_equal "audience-test.csv", @mailer_calls.first[:filename]
  end

  test "invokes ContactingCreatorMailer.subscribers_data with the given recipient" do
    Exports::AudienceExportWorker.new.perform(@seller.id, @recipient.id, @audience_options)

    assert_equal 1, @mailer_calls.length
    assert_equal @recipient, @mailer_calls.first[:recipient]
  end
end
