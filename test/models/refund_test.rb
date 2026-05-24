require "test_helper"

class RefundTest < ActiveSupport::TestCase
  setup do
    @purchase = purchases(:auto_invoice_enabled_purchase)
    @refunding_user = users(:named_seller)
  end

  def build_refund(**attrs)
    Refund.new({
      purchase: @purchase,
      refunding_user_id: @refunding_user.id,
      total_transaction_cents: @purchase.total_transaction_cents,
      amount_cents: @purchase.price_cents,
      creator_tax_cents: @purchase.tax_cents,
      gumroad_tax_cents: @purchase.gumroad_tax_cents,
    }.merge(attrs))
  end

  test "validates that processor_refund_id is unique" do
    build_refund(processor_refund_id: "ref_id").save!
    new_ref = build_refund(processor_refund_id: "ref_id")
    assert_not new_ref.valid?
  end

  test "has an `is_for_fraud` flag" do
    flag_on = build_refund(is_for_fraud: true)
    flag_on.save!
    flag_off = build_refund(is_for_fraud: false)
    flag_off.save!

    assert_equal true, flag_on.is_for_fraud
    assert_equal false, flag_off.is_for_fraud
  end

  test "sets the product and the seller of the purchase" do
    refund = build_refund
    refund.save!
    assert_equal refund.purchase.link, refund.product
    assert_equal refund.purchase.seller, refund.seller
  end
end
