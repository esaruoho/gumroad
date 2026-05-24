require "test_helper"

class EmailInfoTest < ActiveSupport::TestCase
  setup do
    @purchase = purchases(:auto_invoice_enabled_purchase)
  end

  def with_method_stub(klass, method, return_value)
    klass.class_eval do
      alias_method :"__orig_#{method}", method if method_defined?(method)
      define_method(method) { |*_args, **_kwargs| return_value }
    end
    yield
  ensure
    klass.class_eval do
      remove_method method
      if method_defined?(:"__orig_#{method}")
        alias_method method, :"__orig_#{method}"
        remove_method :"__orig_#{method}"
      end
    end
  end

  test "#unsubscribe_buyer for a Purchase calls unsubscribe_buyer on purchase" do
    email_info = CustomerEmailInfo.create!(
      email_name: SendgridEventInfo::RECEIPT_MAILER_METHOD,
      purchase: @purchase,
      state: "created",
    )

    with_method_stub(Purchase, :unsubscribe_buyer, "unsubscribed!") do
      assert_equal "unsubscribed!", email_info.unsubscribe_buyer
    end
  end

  test "#unsubscribe_buyer for a Charge calls unsubscribe_buyer on order" do
    order = Order.create!(purchaser: users(:purchaser))
    order.purchases << @purchase
    charge = Charge.create!(
      order: order,
      seller: @purchase.seller,
      amount_cents: 100,
    )
    charge.purchases << @purchase

    email_info = CustomerEmailInfo.create!(
      purchase_id: nil,
      email_name: SendgridEventInfo::RECEIPT_MAILER_METHOD,
      email_info_charge_attributes: { charge_id: charge.id },
      state: "created",
    )

    with_method_stub(Order, :unsubscribe_buyer, "unsubscribed!") do
      assert_equal "unsubscribed!", email_info.unsubscribe_buyer
    end
  end
end
