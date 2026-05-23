# frozen_string_literal: true

require "test_helper"

class ReceiptPresenter::ShippingInfoTest < ActiveSupport::TestCase
  setup do
    @digital_purchase = purchases(:invoice_seller_purchase)
    @digital_charge = charges(:invoice_seller_charge)
    @physical_purchase = purchases(:shipping_info_physical_purchase)
    @physical_charge = charges(:shipping_info_physical_charge)
  end

  test "assigns chargeable on .new" do
    presenter = ReceiptPresenter::ShippingInfo.new(@digital_purchase)
    assert_equal @digital_purchase, presenter.send(:chargeable)
  end

  test "title is 'Shipping info'" do
    assert_equal "Shipping info", ReceiptPresenter::ShippingInfo.new(@digital_purchase).title
  end

  test "Purchase: includes shipping attributes for a physical product" do
    presenter = ReceiptPresenter::ShippingInfo.new(@physical_purchase)
    assert_equal(
      [
        { label: "Shipping to", value: "Edgar Gumstein" },
        { label: "Shipping address", value: "123 Gum Road<br>San Francisco, CA 94107<br>United States" }
      ],
      presenter.attributes
    )
  end

  test "Purchase: returns empty shipping attributes for a non-physical product" do
    assert_equal [], ReceiptPresenter::ShippingInfo.new(@digital_purchase).attributes
  end

  test "Charge: includes shipping attributes for a physical product" do
    presenter = ReceiptPresenter::ShippingInfo.new(@physical_charge)
    assert_equal(
      [
        { label: "Shipping to", value: "Edgar Gumstein" },
        { label: "Shipping address", value: "123 Gum Road<br>San Francisco, CA 94107<br>United States" }
      ],
      presenter.attributes
    )
  end

  test "Charge: returns empty shipping attributes for a non-physical product" do
    assert_equal [], ReceiptPresenter::ShippingInfo.new(@digital_charge).attributes
  end
end
