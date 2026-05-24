# frozen_string_literal: true

require "test_helper"

class UpdatePurchaseEmailToMatchAccountWorkerTest < ActiveSupport::TestCase
  test "updates email address in every purchased product" do
    user = users(:email_sync_purchaser)
    purchase_a = purchases(:email_sync_purchase_a)
    purchase_b = purchases(:email_sync_purchase_b)

    UpdatePurchaseEmailToMatchAccountWorker.new.perform(user.id)

    assert_equal 2, user.reload.purchases.size
    assert_equal user.email, purchase_a.reload.email
    assert_equal user.email, purchase_b.reload.email
  end
end
