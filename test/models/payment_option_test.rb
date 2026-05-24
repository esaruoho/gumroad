require "test_helper"

class PaymentOptionTest < ActiveSupport::TestCase
  setup do
    @product = links(:po_test_subscription_product)
    @price = prices(:po_test_subscription_product_price)
    @installment_product = links(:po_test_installment_product)
    @installment_plan = product_installment_plans(:po_test_installment_plan)
  end

  # --- validation ---

  test "considers a PaymentOption to be invalid unless all required information is provided" do
    payment_option = PaymentOption.new
    assert_equal false, payment_option.valid?

    payment_option.subscription = subscriptions(:po_test_subscription)
    assert_equal false, payment_option.valid?

    payment_option.price = @product.prices.last
    assert_equal true, payment_option.valid?
  end

  test "requires installment_plan when subscription is an installment plan" do
    subscription = subscriptions(:po_test_validation_subscription)
    assert_equal false, subscription.is_installment_plan

    payment_option = PaymentOption.new(subscription: subscription, price: @price, installment_plan: nil)
    assert_equal true, payment_option.valid?

    subscription.update!(is_installment_plan: true)
    assert_equal false, payment_option.valid?

    payment_option.installment_plan = @installment_plan
    assert_equal true, payment_option.valid?
  end

  # --- #update_subscription_last_payment_option ---

  test "sets correct payment_option on creation and destruction" do
    subscription = subscriptions(:po_test_subscription)

    payment_option_1 = PaymentOption.create!(subscription: subscription, price: @price)
    assert_equal payment_option_1, subscription.reload.last_payment_option

    payment_option_2 = PaymentOption.create!(subscription: subscription, price: @price)
    payment_option_3 = PaymentOption.create!(subscription: subscription, price: @price)
    assert_equal payment_option_3, subscription.reload.last_payment_option

    payment_option_3.destroy
    assert_equal payment_option_2, subscription.reload.last_payment_option

    payment_option_2.mark_deleted!
    assert_equal payment_option_1, subscription.reload.last_payment_option

    payment_option_2.mark_undeleted!
    assert_equal payment_option_2, subscription.reload.last_payment_option
  end
end
