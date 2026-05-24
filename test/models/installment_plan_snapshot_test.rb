# frozen_string_literal: true

require "test_helper"

class InstallmentPlanSnapshotTest < ActiveSupport::TestCase
  setup do
    # Reuse an existing payment_option fixture; the deactivated_worker_alive payment_option
    # is unused for installment_plan_snapshots so we can attach freely.
    @payment_option = payment_options(:deactivated_worker_alive_payment_option)
  end

  def build_snapshot(**attrs)
    InstallmentPlanSnapshot.new(
      {
        payment_option: @payment_option,
        number_of_installments: 3,
        recurrence: "monthly",
        total_price_cents: 15_000,
      }.merge(attrs)
    )
  end

  # ----- associations -----

  test "belongs to payment_option" do
    snapshot = build_snapshot
    assert_equal @payment_option, snapshot.payment_option
  end

  # ----- validations: number_of_installments -----

  test "number_of_installments is required" do
    snapshot = build_snapshot(number_of_installments: nil)
    refute snapshot.valid?
    assert_includes snapshot.errors[:number_of_installments], "can't be blank"
  end

  test "number_of_installments must be greater than 0" do
    snapshot = build_snapshot(number_of_installments: 0)
    refute snapshot.valid?
    assert_includes snapshot.errors[:number_of_installments], "must be greater than 0"
  end

  test "number_of_installments must be an integer" do
    snapshot = build_snapshot(number_of_installments: 3.5)
    refute snapshot.valid?
    assert_includes snapshot.errors[:number_of_installments], "must be an integer"
  end

  # ----- validations: recurrence -----

  test "recurrence is required" do
    snapshot = build_snapshot(recurrence: nil)
    refute snapshot.valid?
    assert_includes snapshot.errors[:recurrence], "can't be blank"
  end

  # ----- validations: total_price_cents -----

  test "total_price_cents is required" do
    snapshot = build_snapshot(total_price_cents: nil)
    refute snapshot.valid?
    assert_includes snapshot.errors[:total_price_cents], "can't be blank"
  end

  test "total_price_cents must be greater than 0" do
    snapshot = build_snapshot(total_price_cents: 0)
    refute snapshot.valid?
    assert_includes snapshot.errors[:total_price_cents], "must be greater than 0"
  end

  test "total_price_cents must be an integer" do
    snapshot = build_snapshot(total_price_cents: 100.5)
    refute snapshot.valid?
    assert_includes snapshot.errors[:total_price_cents], "must be an integer"
  end

  # ----- validations: payment_option uniqueness -----

  test "payment_option uniqueness" do
    build_snapshot.save!
    duplicate = build_snapshot
    refute duplicate.valid?
    assert_includes duplicate.errors[:payment_option], "has already been taken"
  end

  test "valid with all required attributes" do
    assert build_snapshot.valid?
  end

  # ----- #calculate_installment_payment_price_cents -----

  test "calculates equal payments when total divides evenly" do
    snapshot = build_snapshot(number_of_installments: 3, total_price_cents: 15_000)
    snapshot.save!
    assert_equal [5_000, 5_000, 5_000], snapshot.calculate_installment_payment_price_cents
  end

  test "adds remainder to first payment when total has remainder" do
    snapshot = build_snapshot(number_of_installments: 3, total_price_cents: 10_000)
    snapshot.save!
    payments = snapshot.calculate_installment_payment_price_cents
    assert_equal [3_334, 3_333, 3_333], payments
    assert_equal 10_000, payments.sum
  end

  test "handles larger remainders correctly" do
    snapshot = build_snapshot(number_of_installments: 3, total_price_cents: 14_700)
    snapshot.save!
    assert_equal [4_900, 4_900, 4_900], snapshot.calculate_installment_payment_price_cents
  end

  test "returns full amount for single installment" do
    snapshot = build_snapshot(number_of_installments: 1, total_price_cents: 10_000)
    snapshot.save!
    assert_equal [10_000], snapshot.calculate_installment_payment_price_cents
  end

  test "handles 12 installments correctly" do
    snapshot = build_snapshot(number_of_installments: 12, total_price_cents: 12_000)
    snapshot.save!
    assert_equal [1_000] * 12, snapshot.calculate_installment_payment_price_cents
  end
end
