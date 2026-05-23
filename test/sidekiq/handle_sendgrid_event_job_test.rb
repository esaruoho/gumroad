# frozen_string_literal: true

require "test_helper"

class HandleSendgridEventJobTest < ActiveSupport::TestCase
  test "does nothing when the event type is not supported" do
    params = {
      "_json" => [
        {
          "event" => "processed",
          "type" => "CustomerMailer.receipt",
          "identifier" => "[1]"
        }
      ]
    }

    HandleEmailEventInfo::ForInstallmentEmail.stub(:perform, ->(*) { flunk "should not be called" }) do
      HandleEmailEventInfo::ForReceiptEmail.stub(:perform, ->(*) { flunk "should not be called" }) do
        HandleEmailEventInfo::ForAbandonedCartEmail.stub(:perform, ->(*) { flunk "should not be called" }) do
          HandleSendgridEventJob.new.perform(params)
        end
      end
    end
  end

  test "does nothing when the event data is invalid" do
    params = { "_json" => [{ "foo" => "bar" }] }

    HandleEmailEventInfo::ForInstallmentEmail.stub(:perform, ->(*) { flunk "should not be called" }) do
      HandleEmailEventInfo::ForReceiptEmail.stub(:perform, ->(*) { flunk "should not be called" }) do
        HandleEmailEventInfo::ForAbandonedCartEmail.stub(:perform, ->(*) { flunk "should not be called" }) do
          HandleSendgridEventJob.new.perform(params)
        end
      end
    end
  end

  test "handles events for abandoned cart emails" do
    params = { "_json" => [{ "event" => "delivered", "mailer_class" => "CustomerMailer", "mailer_method" => "abandoned_cart", "mailer_args" => "[3783, {\"5296\"=>[153758, 163413], \"5644\"=>[163413]}]" }] }

    called_with = nil
    HandleEmailEventInfo::ForInstallmentEmail.stub(:perform, ->(*) { flunk "should not be called" }) do
      HandleEmailEventInfo::ForReceiptEmail.stub(:perform, ->(*) { flunk "should not be called" }) do
        HandleEmailEventInfo::ForAbandonedCartEmail.stub(:perform, ->(info) { called_with = info }) do
          HandleSendgridEventJob.new.perform(params)
        end
      end
    end

    assert_kind_of SendgridEventInfo, called_with
  end
end
