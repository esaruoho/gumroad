# frozen_string_literal: true

require "test_helper"

class ExpireRentalPurchasesWorkerTest < ActiveSupport::TestCase
  test "updates only rental purchases" do
    rental = purchases(:rental_expiry_purchase_1)
    non_rental = purchases(:rental_expiry_non_rental_purchase)

    ExpireRentalPurchasesWorker.new.perform

    assert_equal true, rental.reload.rental_expired
    assert_nil non_rental.reload.rental_expired
  end

  test "updates only rental purchases with rental url redirects past expiry dates" do
    p1 = purchases(:rental_expiry_purchase_1)
    p2 = purchases(:rental_expiry_purchase_2)
    p3 = purchases(:rental_expiry_purchase_3)
    p4 = purchases(:rental_expiry_purchase_4)

    ExpireRentalPurchasesWorker.new.perform

    assert_equal true, p1.reload.rental_expired
    assert_equal false, p2.reload.rental_expired
    assert_equal true, p3.reload.rental_expired
    assert_equal false, p4.reload.rental_expired
  end
end
