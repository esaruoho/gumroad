# frozen_string_literal: true

require "test_helper"

class AttachPastPurchasesToUserWorkerTest < ActiveSupport::TestCase
  test "attaches unlinked purchases matching the user's email" do
    user = users(:basic_user)
    other_user = users(:two_factor_user)

    purchase1 = purchases(:named_seller_call_purchase)
    purchase1.update_columns(email: user.email, purchaser_id: nil)
    purchase2 = purchases(:another_seller_call_purchase)
    purchase2.update_columns(email: user.email, purchaser_id: nil)
    purchase_already_linked = purchases(:pdf_stamping_purchase)
    purchase_already_linked.update_columns(email: user.email, purchaser_id: other_user.id)

    attached_for = []
    mod = Module.new
    mod.send(:define_method, :attach_to_user_and_card) do |u, _ch, _md|
      attached_for << [id, u.id]
    end
    Purchase.prepend(mod)

    AttachPastPurchasesToUserWorker.new.perform(user.id)

    assert_includes attached_for, [purchase1.id, user.id]
    assert_includes attached_for, [purchase2.id, user.id]
    refute_includes attached_for.map(&:first), purchase_already_linked.id
  ensure
    mod.module_eval { remove_method(:attach_to_user_and_card) } if mod
  end

  test "does nothing when user has a blank email" do
    user = users(:basic_user)
    user.update_column(:email, "")

    assert_nothing_raised { AttachPastPurchasesToUserWorker.new.perform(user.id) }
  end

  test "does nothing when there are no unlinked purchases" do
    user = users(:basic_user)

    assert_nothing_raised { AttachPastPurchasesToUserWorker.new.perform(user.id) }
  end
end
