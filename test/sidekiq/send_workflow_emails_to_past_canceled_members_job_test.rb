# frozen_string_literal: true

require "test_helper"

class SendWorkflowEmailsToPastCanceledMembersJobTest < ActiveSupport::TestCase
  setup do
    @product = links(:named_seller_product)
  end

  def fake_rule(delay: 7.days, version: 1)
    rule = Object.new
    rule.define_singleton_method(:delayed_delivery_time) { delay }
    rule.define_singleton_method(:version) { version }
    rule
  end

  def fake_installment(workflow:, rule:, published: true, alive: true, id: 42)
    inst = Object.new
    inst.define_singleton_method(:id) { id }
    inst.define_singleton_method(:workflow) { workflow }
    inst.define_singleton_method(:installment_rule) { rule }
    inst.define_singleton_method(:alive?) { alive }
    inst.define_singleton_method(:published?) { published }
    inst
  end

  def fake_workflow(alive: true, mct: true, past: true, scope_type: :seller, link_id: nil, seller_id: nil)
    wf = Object.new
    wf.define_singleton_method(:alive?) { alive }
    wf.define_singleton_method(:member_cancellation_trigger?) { mct }
    wf.define_singleton_method(:send_to_past_customers?) { past }
    wf.define_singleton_method(:seller_or_product_or_variant_type?) { true }
    wf.define_singleton_method(:product_or_variant_type?) { scope_type == :product }
    wf.define_singleton_method(:link_id) { link_id }
    wf.define_singleton_method(:seller_id) { seller_id }
    wf.define_singleton_method(:applies_to_purchase?) { |_purchase| true }
    wf
  end

  test "returns early when workflow is not alive" do
    enqueued = []
    SendWorkflowInstallmentWorker.stub(:perform_at, ->(*a) { enqueued << a }) do
      wf = fake_workflow(alive: false)
      inst = fake_installment(workflow: wf, rule: fake_rule)
      Installment.stub(:find, ->(_id) { inst }) do
        SendWorkflowEmailsToPastCanceledMembersJob.new.perform(inst.id)
      end
    end
    assert_empty enqueued
  end

  test "returns early when workflow is not a member_cancellation_trigger" do
    enqueued = []
    SendWorkflowInstallmentWorker.stub(:perform_at, ->(*a) { enqueued << a }) do
      wf = fake_workflow(mct: false)
      inst = fake_installment(workflow: wf, rule: fake_rule)
      Installment.stub(:find, ->(_id) { inst }) do
        SendWorkflowEmailsToPastCanceledMembersJob.new.perform(inst.id)
      end
    end
    assert_empty enqueued
  end

  test "enqueues SendWorkflowInstallmentWorker for each cancelled subscription with original_purchase" do
    sub = subscriptions(:deactivated_worker_cancelled_past_subscription)
    purchase = Purchase.new(seller: @product.user, link: @product, email: "b@example.com",
                             price_cents: 100, total_transaction_cents: 100, fee_cents: 0,
                             purchase_state: "successful")
    purchase.save!(validate: false)
    cancelled_at = 2.days.ago
    deactivated_at = 1.day.ago
    sub.update_columns(deactivated_at: deactivated_at, cancelled_at: cancelled_at, seller_id: @product.user_id, link_id: @product.id)
    # Stash-and-restore: Subscription has native `cancelled?` and `original_purchase` methods.
    # remove_method on an overridden-via-define_method would strip the original
    # too and leak NoMethodError into sibling tests.
    orig_cancelled = Subscription.instance_method(:cancelled?)
    orig_original_purchase = Subscription.instance_method(:original_purchase)
    Subscription.define_method(:cancelled?) { |*_a, **_kw| true }
    Subscription.define_method(:original_purchase) { purchase }

    rule = fake_rule(delay: 14.days, version: 3)
    wf = fake_workflow(alive: true, scope_type: :seller, seller_id: @product.user_id)
    inst = fake_installment(workflow: wf, rule: rule, id: 4242)

    enqueued = []
    begin
      SendWorkflowInstallmentWorker.stub(:perform_at, ->(*args) { enqueued << args }) do
        Installment.stub(:find, ->(_id) { inst }) do
          SendWorkflowEmailsToPastCanceledMembersJob.new.perform(inst.id)
        end
      end
    ensure
      Subscription.define_method(:cancelled?, orig_cancelled)
      Subscription.define_method(:original_purchase, orig_original_purchase)
    end
    # There may be multiple cancelled+deactivated subscriptions in fixtures, but
    # at minimum we expect one enqueue for our subject.
    assert enqueued.any? { |args| args[1] == 4242 && args[2] == 3 }
  end
end
