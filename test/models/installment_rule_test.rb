# frozen_string_literal: true

require "test_helper"

class InstallmentRuleTest < ActiveSupport::TestCase
  setup do
    @product = links(:named_seller_product)
    @post = Installment.create!(
      seller_id: @product.user_id,
      link_id: @product.id,
      name: "Test post",
      message: "Hello",
      installment_type: "product",
      flags: 128,
    )
  end

  test "has the installment_rule starting version be 1" do
    rule = InstallmentRule.create!(installment: @post, to_be_published_at: 1.week.from_now)
    assert_equal 1, rule.reload.version
  end

  test "increments the version when to_be_published_at changes" do
    rule = InstallmentRule.create!(installment: @post, to_be_published_at: 1.week.from_now)
    rule.update!(to_be_published_at: 1.month.from_now)
    assert_equal 2, rule.reload.version
  end

  test "increments the version if delayed_delivery_time is changed" do
    rule = InstallmentRule.create!(installment: @post, to_be_published_at: 1.week.from_now)
    rule.delayed_delivery_time = 100
    rule.save!
    assert_equal 2, rule.reload.version
  end

  test "does not increment the version if period is changed" do
    rule = InstallmentRule.create!(installment: @post, to_be_published_at: 1.week.from_now)
    initial = rule.reload.version
    rule.time_period = "DAY"
    rule.save!
    assert_equal initial, rule.reload.version
  end

  test "displayable_time_duration returns the correct duration based on the time period" do
    rule = InstallmentRule.create!(installment: @post, delayed_delivery_time: 1.week, time_period: "week", to_be_published_at: 1.week.from_now)

    assert_equal 1, rule.displayable_time_duration
    rule.update!(delayed_delivery_time: 2.weeks, time_period: "day")
    assert_equal 14, rule.displayable_time_duration
    rule.update!(delayed_delivery_time: 2.hours, time_period: "hour")
    assert_equal 2, rule.displayable_time_duration
    rule.update!(delayed_delivery_time: 1.month, time_period: "month")
    assert_equal 1, rule.displayable_time_duration
  end

  test "to_be_published_at allows nil for workflow posts" do
    workflow = Workflow.create!(seller_id: @product.user_id, link_id: @product.id, workflow_type: "audience", name: "wf")
    workflow_post = Installment.create!(seller_id: @product.user_id, workflow_id: workflow.id, name: "wf post", message: "x", installment_type: "audience", flags: 128)
    rule = InstallmentRule.create!(installment: workflow_post, to_be_published_at: nil)
    assert_nil rule.to_be_published_at
    assert rule.valid?
  end

  test "to_be_published_at disallows past time for workflow posts" do
    workflow = Workflow.create!(seller_id: @product.user_id, link_id: @product.id, workflow_type: "audience", name: "wf")
    workflow_post = Installment.create!(seller_id: @product.user_id, workflow_id: workflow.id, name: "wf post", message: "x", installment_type: "audience", flags: 128)
    rule = InstallmentRule.create!(installment: workflow_post, to_be_published_at: nil)
    rule.to_be_published_at = Time.current
    refute rule.valid?
    assert_includes rule.errors.full_messages, "Please select a date and time in the future."
  end

  test "to_be_published_at allows past time when about to be marked as deleted" do
    workflow = Workflow.create!(seller_id: @product.user_id, link_id: @product.id, workflow_type: "audience", name: "wf")
    workflow_post = Installment.create!(seller_id: @product.user_id, workflow_id: workflow.id, name: "wf post", message: "x", installment_type: "audience", flags: 128)
    rule = InstallmentRule.create!(installment: workflow_post, to_be_published_at: nil)
    rule.to_be_published_at = Time.current
    rule.deleted_at = Time.current
    assert rule.valid?
  end

  test "to_be_published_at_must_exist_for_non_workflow_posts disallows nil" do
    rule = InstallmentRule.new(installment: @post, to_be_published_at: nil)
    refute rule.valid?
    assert_includes rule.errors.full_messages, "Please select a date and time in the future."
  end
end
