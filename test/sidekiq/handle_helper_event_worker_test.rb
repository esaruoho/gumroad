# frozen_string_literal: true

require "test_helper"

class HandleHelperEventWorkerTest < ActiveSupport::TestCase
  setup do
    @params = {
      "event" => "conversation.created",
      "payload" => {
        "conversation_id" => "6d389b441fcb17378effbdc4192ee69d",
        "email_id" => "123",
        "email_from" => "user@example.com",
        "subject" => "Some subject",
        "body" => "Some body"
      },
    }
    @event = @params["event"]
    @payload = @params["payload"].as_json
    @prepended_modules = []
  end

  teardown do
    # Best-effort: we can't unprepend cleanly, but each Module instance is unique.
    # Define no-op overrides on the prepended modules to neutralize residual effect.
    @prepended_modules.each { |mod, _klass| mod.module_eval { instance_methods(false).each { |m| remove_method(m) } } }
  end

  def stub_instance_method(klass, method, &block)
    mod = Module.new
    mod.send(:define_method, method, &block)
    klass.prepend(mod)
    @prepended_modules << [mod, klass]
  end

  test "triggers UnblockEmailService" do
    user_info_stub = { user: nil, account_infos: [], purchase_infos: [], recent_purchase: nil }
    stub_instance_method(HelperUserInfoService, :user_info) { user_info_stub }

    process_called = false
    replied_called = false
    stub_instance_method(Helper::UnblockEmailService, :process) { process_called = true }
    stub_instance_method(Helper::UnblockEmailService, :replied?) { replied_called = true; false }

    HandleHelperEventWorker.new.perform(@event, @payload)

    assert process_called, "expected #process to be called"
    assert replied_called, "expected #replied? to be called"
  end

  test "does not trigger UnblockEmailService when event is invalid" do
    process_called = false
    stub_instance_method(Helper::UnblockEmailService, :process) { process_called = true }

    HandleHelperEventWorker.new.perform("invalid_event", @payload)

    refute process_called
  end

  test "does not trigger UnblockEmailService when there is no email" do
    process_called = false
    stub_instance_method(Helper::UnblockEmailService, :process) { process_called = true }

    @payload["email_from"] = nil
    HandleHelperEventWorker.new.perform(@event, @payload)

    refute process_called
  end

  test "triggers BlockStripeSuspectedFraudulentPaymentsWorker and skips UnblockEmailService for new Stripe fraud email" do
    @payload["email_from"] = BlockStripeSuspectedFraudulentPaymentsWorker::STRIPE_EMAIL_SENDER
    @payload["subject"] = BlockStripeSuspectedFraudulentPaymentsWorker::POSSIBLE_CONVERSATION_SUBJECTS.sample

    block_args = nil
    stub_instance_method(BlockStripeSuspectedFraudulentPaymentsWorker, :perform) do |conversation_id, email_from, body|
      block_args = [conversation_id, email_from, body]
    end
    process_called = false
    stub_instance_method(Helper::UnblockEmailService, :process) { process_called = true }

    HandleHelperEventWorker.new.perform(@event, @payload)

    assert_equal [@payload["conversation_id"], @payload["email_from"], @payload["body"]], block_args
    refute process_called
  end
end
