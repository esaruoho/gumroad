# frozen_string_literal: true

require "test_helper"

class SuspendUsersWorkerTest < ActiveSupport::TestCase
  setup do
    @author = users(:named_seller)
    @target = users(:basic_user)
  end

  test "calls suspend_for_tos_violation on each user with the constructed content string" do
    captured = []
    User.define_method(:suspend_for_tos_violation) do |author_id:, content:|
      captured << [self.id, author_id, content]
    end
    # Make `was_suspended` true so the scheduled-payout branch is skipped.
    User.define_method(:suspended?) { true }

    begin
      SuspendUsersWorker.new.perform(@author.id, [@target.id], "TOS reason", "extra notes")
    ensure
      User.remove_method(:suspend_for_tos_violation) if User.method_defined?(:suspend_for_tos_violation)
      User.remove_method(:suspended?) if User.method_defined?(:suspended?)
    end
    assert_equal 1, captured.size
    target_id, author_id, content = captured.first
    assert_equal @target.id, target_id
    assert_equal @author.id, author_id
    assert_includes content, "TOS reason"
    assert_includes content, "Additional notes: extra notes"
    assert_includes content, @author.name_or_username
  end

  test "creates scheduled payout when user transitions to suspended and balance is positive" do
    suspended_states = { @target.id => false }
    User.define_method(:suspend_for_tos_violation) { |**_kw| suspended_states[self.id] = true }
    User.define_method(:suspended?) { suspended_states[self.id] }
    User.define_method(:unpaid_balance_cents) { 5_000_00 }

    begin
      SuspendUsersWorker.new.perform(@author.id, [@target.id], "reason", nil,
                                      "action" => "payout", "delay_days" => 30)
    ensure
      %i[suspend_for_tos_violation suspended? unpaid_balance_cents].each do |m|
        User.remove_method(m) if User.method_defined?(m)
      end
    end
    payouts = @target.scheduled_payouts.reload.to_a
    assert_equal 1, payouts.size
    assert_equal "payout", payouts.first.action
    assert_equal 30, payouts.first.delay_days
    assert_equal 5_000_00, payouts.first.payout_amount_cents
    comments = @target.comments.reload.to_a
    assert_equal 1, comments.size
    assert_includes comments.first.content, "Scheduled payout"
  end
end
