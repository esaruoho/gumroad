# frozen_string_literal: true

require "test_helper"

class BlockStripeSuspectedFraudulentPaymentsWorkerTest < ActiveSupport::TestCase
  # Full-flow coverage (purchase refund + buyer-block + Helper note/close) requires
  # a multi-purchase Stripe-charge fixture roster, ChargeProcessor.refund! stubs, and
  # `expect_any_instance_of(Helper::Client)` which has no clean Minitest equivalent.
  # That happy-path branch stays deferred; this backfill covers the regex parser,
  # the non-Stripe email early-return guard, and the empty-records short-circuit —
  # all branches that exercise `perform` without touching Stripe or Helper.

  setup do
    @payload = JSON.parse(File.read(Rails.root.join("spec", "support", "fixtures", "helper_conversation_created.json")))["payload"]
    @helper_new_calls = 0
    counter = -> { @helper_new_calls += 1 }
    @original_helper_new = Helper::Client.method(:new)
    Helper::Client.define_singleton_method(:new) do |*_args, **_kw|
      counter.call
      raise "Helper::Client should not be instantiated in this test"
    end
  end

  teardown do
    Helper::Client.singleton_class.send(:remove_method, :new)
    Helper::Client.define_singleton_method(:new, @original_helper_new) if @original_helper_new
  end

  test "#parse_payment_records_from_body extracts Stripe charge IDs from the email body" do
    records = BlockStripeSuspectedFraudulentPaymentsWorker.new.send(:parse_payment_records_from_body, @payload["body"])

    assert_equal 20, records.length
    assert_equal "ch_2LBu5J9e1RjUNIyY1Q3Kw06Q", records.first
    assert_equal "ch_2LBu5X9e1RjUNIyY1PerqPRf", records.last
    assert records.all? { |r| r.start_with?("ch_") }
  end

  test "#perform short-circuits when email_from is not the Stripe sender (no Helper instantiation)" do
    BlockStripeSuspectedFraudulentPaymentsWorker.new.perform(
      @payload["conversation_id"], "not-stripe@example.com", @payload["body"]
    )

    assert_equal 0, @helper_new_calls, "Helper::Client.new must not be called for non-Stripe email"
  end

  test "#perform short-circuits when body has no charge IDs (no Helper instantiation)" do
    BlockStripeSuspectedFraudulentPaymentsWorker.new.perform(
      @payload["conversation_id"], BlockStripeSuspectedFraudulentPaymentsWorker::STRIPE_EMAIL_SENDER,
      "Body with no charge identifiers at all."
    )

    assert_equal 0, @helper_new_calls, "Helper::Client.new must not be called when no records are parsed"
  end

  test "#perform notifies ErrorNotifier and treats a nil body as no records (no Helper instantiation)" do
    notified = []
    original = ErrorNotifier.method(:notify)
    ErrorNotifier.define_singleton_method(:notify) { |err| notified << err }

    begin
      BlockStripeSuspectedFraudulentPaymentsWorker.new.perform(
        @payload["conversation_id"], BlockStripeSuspectedFraudulentPaymentsWorker::STRIPE_EMAIL_SENDER, nil
      )
    ensure
      ErrorNotifier.singleton_class.send(:remove_method, :notify)
      ErrorNotifier.define_singleton_method(:notify, original)
    end

    assert_equal 1, notified.size
    assert_equal 0, @helper_new_calls, "Helper::Client.new must not be called when parsing fails"
  end
end
