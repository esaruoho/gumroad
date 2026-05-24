# frozen_string_literal: true

require "test_helper"

class InvoicePresenter::SellerInfoTest < ActiveSupport::TestCase
  setup do
    @seller = users(:invoice_seller)
    @purchase = purchases(:invoice_seller_purchase)
    @charge = charges(:invoice_seller_charge)
  end

  # Shared expectations on a chargeable.
  def assert_seller_info(chargeable)
    presenter = InvoicePresenter::SellerInfo.new(chargeable)
    assert_equal "Creator", presenter.heading
    assert_equal(
      [
        {
          label: nil,
          value: @seller.display_name,
          link: @seller.subdomain_with_protocol
        },
        {
          label: "Email",
          value: @seller.support_or_form_email
        }
      ],
      presenter.attributes
    )
  end

  test "Purchase: returns the seller heading and attributes" do
    assert_seller_info(@purchase)
  end

  test "Charge: returns the seller heading and attributes" do
    assert_seller_info(@charge)
  end
end
