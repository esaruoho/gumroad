# frozen_string_literal: true

require "test_helper"

class BlockStripeSuspectedFraudulentPaymentsWorkerTest < ActiveSupport::TestCase
  setup do
    @payload = JSON.parse(file_fixture("helper_conversation_created.json").read)["payload"]
    @admin = users(:admin_user)
    @prev_admin_id = Object.send(:remove_const, :GUMROAD_ADMIN_ID) if Object.const_defined?(:GUMROAD_ADMIN_ID)
    Object.const_set(:GUMROAD_ADMIN_ID, @admin.id)

    @helper_calls = []
    helper_calls = @helper_calls
    @helper_mod = Module.new
    @helper_mod.send(:define_method, :add_note) { |**kwargs| helper_calls << [:add_note, kwargs] }
    @helper_mod.send(:define_method, :close_conversation) { |**kwargs| helper_calls << [:close_conversation, kwargs] }
    Helper::Client.prepend(@helper_mod)
  end

  teardown do
    Object.send(:remove_const, :GUMROAD_ADMIN_ID) if Object.const_defined?(:GUMROAD_ADMIN_ID)
    Object.const_set(:GUMROAD_ADMIN_ID, @prev_admin_id) if @prev_admin_id
  end

  test "parses payment records from Stripe emails" do
    records = BlockStripeSuspectedFraudulentPaymentsWorker.new.send(:parse_payment_records_from_body, @payload["body"])
    assert_equal 20, records.length
    assert_equal "ch_2LBu5J9e1RjUNIyY1Q3Kw06Q", records.first
    assert_equal "ch_2LBu5X9e1RjUNIyY1PerqPRf", records.last
  end

  test "blocks the listed purchases, adds a note, and closes the ticket" do
    charge_ids = ["ch_2LBu5J9e1RjUNIyY1Q3Kw06Q", "ch_2LBu5X9e1RjUNIyY1PerqPRf"]

    refund_calls = []
    block_calls = []
    refund_mod = Module.new
    refund_mod.send(:define_method, :refund_for_fraud!) { |aid| refund_calls << [stripe_transaction_id, aid] }
    refund_mod.send(:define_method, :block_buyer!) { |**kw| block_calls << [stripe_transaction_id, kw] }
    refund_mod.send(:define_method, :buyer_blocked?) { false }
    Purchase.prepend(refund_mod)

    p1 = purchases(:named_seller_call_purchase)
    p2 = purchases(:another_seller_call_purchase)
    p1.update_columns(stripe_transaction_id: charge_ids[0], created_at: 1.day.ago)
    p2.update_columns(stripe_transaction_id: charge_ids[1], created_at: 1.day.ago)

    BlockStripeSuspectedFraudulentPaymentsWorker.new.perform(@payload["conversation_id"], @payload["email_from"], @payload["body"])

    assert_equal charge_ids.sort, refund_calls.map(&:first).sort
    assert_includes @helper_calls, [:add_note, { conversation_id: @payload["conversation_id"], message: BlockStripeSuspectedFraudulentPaymentsWorker::HELPER_NOTE_CONTENT }]
    assert_includes @helper_calls, [:close_conversation, { conversation_id: @payload["conversation_id"] }]
  end

  test "does not trigger any processing when email is not from Stripe" do
    BlockStripeSuspectedFraudulentPaymentsWorker.new.perform(@payload["conversation_id"], "not_stripe@example.com", @payload["body"])
    assert_empty @helper_calls
  end

  test "does not trigger any processing when email body contains no transaction IDs" do
    BlockStripeSuspectedFraudulentPaymentsWorker.new.perform(@payload["conversation_id"], @payload["email_from"], "Some body")
    assert_empty @helper_calls
  end

  test "notifies error tracker when there is an error" do
    notified = []
    err_mod = Module.new
    err_mod.send(:define_method, :notify) { |err, *_| notified << err }
    ErrorNotifier.singleton_class.prepend(err_mod)

    BlockStripeSuspectedFraudulentPaymentsWorker.new.perform(@payload["conversation_id"], @payload["email_from"], nil)
    assert_equal 1, notified.size
  end
end
