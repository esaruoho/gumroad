# frozen_string_literal: true

require "test_helper"

class PaymentOptionInstallmentPlanSnapshotTest < ActiveSupport::TestCase
  setup do
    @payment_option = payment_options(:po_test_validation_phantom_payment_option)
    @installment_plan = product_installment_plans(:po_test_installment_plan)
    # Clear any pre-existing snapshot rows.
    InstallmentPlanSnapshot.where(payment_option_id: @payment_option.id).delete_all
  end

  # ----- association -----

  test "has one installment_plan_snapshot" do
    assert_respond_to @payment_option, :installment_plan_snapshot
  end

  test "can build an installment_plan_snapshot" do
    snapshot = @payment_option.build_installment_plan_snapshot(
      number_of_installments: 3,
      recurrence: "monthly",
      total_price_cents: 14700
    )

    assert_kind_of InstallmentPlanSnapshot, snapshot
    assert_equal @payment_option, snapshot.payment_option
    assert_equal 3, snapshot.number_of_installments
    assert_equal "monthly", snapshot.recurrence
    assert_equal 14700, snapshot.total_price_cents
  end

  # ----- snapshot creation -----

  test "creates snapshot with correct attributes" do
    @payment_option.build_installment_plan_snapshot(
      number_of_installments: @installment_plan.number_of_installments,
      recurrence: @installment_plan.recurrence,
      total_price_cents: 14700,
    )
    @payment_option.save!

    snapshot = @payment_option.reload.installment_plan_snapshot
    assert snapshot.present?
    assert_equal @installment_plan.number_of_installments, snapshot.number_of_installments
    assert_equal "monthly", snapshot.recurrence
    assert_equal 14700, snapshot.total_price_cents
  end

  # ----- price protection -----

  test "maintains original installment amounts when product price increases" do
    snapshot = InstallmentPlanSnapshot.create!(
      payment_option: @payment_option,
      number_of_installments: 3,
      recurrence: "monthly",
      total_price_cents: 14700,
    )

    assert_equal 14700, snapshot.total_price_cents
    assert_equal 3, snapshot.number_of_installments
    assert_equal [4900, 4900, 4900], snapshot.calculate_installment_payment_price_cents
  end

  test "maintains original installment amounts when product price decreases" do
    snapshot = InstallmentPlanSnapshot.create!(
      payment_option: @payment_option,
      number_of_installments: 3,
      recurrence: "monthly",
      total_price_cents: 14700,
    )

    # Simulate the product price changing — snapshot must stay pinned.
    product = @payment_option.subscription.link
    product.update_columns(price_cents: 10000)

    snapshot.reload
    assert_equal 14700, snapshot.total_price_cents
    assert_equal [4900, 4900, 4900], snapshot.calculate_installment_payment_price_cents
  end

  # ----- installment configuration protection -----

  test "maintains original count when installment_plan changes from 3 to 2" do
    snapshot = InstallmentPlanSnapshot.create!(
      payment_option: @payment_option,
      number_of_installments: 3,
      recurrence: "monthly",
      total_price_cents: 14700,
    )

    @installment_plan.update!(number_of_installments: 2)

    snapshot.reload
    assert_equal 3, snapshot.number_of_installments
    assert_equal 2, @installment_plan.reload.number_of_installments
  end

  test "maintains original count when installment_plan changes from 3 to 5" do
    snapshot = InstallmentPlanSnapshot.create!(
      payment_option: @payment_option,
      number_of_installments: 3,
      recurrence: "monthly",
      total_price_cents: 14700,
    )

    @installment_plan.update!(number_of_installments: 5)

    snapshot.reload
    assert_equal 3, snapshot.number_of_installments
    assert_equal 5, @installment_plan.reload.number_of_installments
  end

  # ----- backwards compatibility -----

  test "can still access installment_plan through payment_option when no snapshot exists" do
    assert_nil @payment_option.installment_plan_snapshot
    assert_equal @installment_plan, @payment_option.installment_plan
    assert_equal @installment_plan.number_of_installments, @payment_option.installment_plan.number_of_installments
    assert_equal "monthly", @payment_option.installment_plan.recurrence
  end

  test "can access both snapshot and live plan when snapshot exists" do
    InstallmentPlanSnapshot.create!(
      payment_option: @payment_option,
      number_of_installments: 5,
      recurrence: "weekly",
      total_price_cents: 20000,
    )

    @payment_option.reload
    assert_equal 5, @payment_option.installment_plan_snapshot.number_of_installments
    assert_equal "weekly", @payment_option.installment_plan_snapshot.recurrence

    assert_equal @installment_plan.number_of_installments, @payment_option.installment_plan.number_of_installments
    assert_equal "monthly", @payment_option.installment_plan.recurrence
  end
end
