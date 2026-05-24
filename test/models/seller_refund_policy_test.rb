# frozen_string_literal: true

require "test_helper"

class SellerRefundPolicyTest < ActiveSupport::TestCase
  setup do
    @seller = users(:named_seller)
    @refund_policy = SellerRefundPolicy.find_by!(seller: @seller, product_id: nil)
  end

  # ---- validations ----

  test "validates presence of seller" do
    refund_policy = SellerRefundPolicy.new
    assert_not refund_policy.valid?
    assert_equal :blank, refund_policy.errors.details[:seller].first[:error]
  end

  test "validates seller uniqueness when refund policy for seller exists" do
    new_refund_policy = @refund_policy.dup
    assert_not new_refund_policy.valid?
    assert_equal :taken, new_refund_policy.errors.details[:seller].first[:error]
  end

  test "validates fine_print length" do
    @refund_policy.fine_print = "a" * 3001
    assert_not @refund_policy.valid?
    assert_equal :too_long, @refund_policy.errors.details[:fine_print].first[:error]
  end

  test "strips tags from fine_print" do
    @refund_policy.fine_print = "<p>This is a account-level refund policy</p>"
    @refund_policy.save!
    assert_equal "This is a account-level refund policy", @refund_policy.fine_print
  end

  # ---- stripped_fields ----

  test "stripped_fields strips leading and trailing spaces for fine_print" do
    @refund_policy.update!(fine_print: "  This is a account-level refund policy  ")
    assert_equal "This is a account-level refund policy", @refund_policy.fine_print
  end

  test "stripped_fields nullifies empty fine_print" do
    @refund_policy.update!(fine_print: "  This is a account-level refund policy  ")
    @refund_policy.update!(fine_print: "")
    assert_nil @refund_policy.fine_print
  end

  # ---- #as_json ----

  test "#as_json returns a hash with refund details" do
    assert_equal(
      {
        fine_print: @refund_policy.fine_print,
        id: @refund_policy.external_id,
        title: @refund_policy.title,
      },
      @refund_policy.as_json
    )
  end
end
