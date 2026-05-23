# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during fixtures-only migration.
# Requires gifts.yml (giftee/gifter purchase rows + gift linkage) plus a
# membership_purchase fixture row wired to a membership product, a price row
# with `recurrence:`, and a subscription row tying back to the gifter
# purchase. Membership-shaped fixture chain not yet seeded.
#
# Original spec: spec/presenters/receipt_presenter/giftee_manage_subscription_spec.rb (deleted)
class ReceiptPresenter::GifteeManageSubscriptionTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — needs gifts/membership_purchase/subscription fixture chain" do
    skip "TODO: migrate spec/presenters/receipt_presenter/giftee_manage_subscription_spec.rb (3 FB refs, gifts + membership_purchase + subscription chain)"
  end
end
