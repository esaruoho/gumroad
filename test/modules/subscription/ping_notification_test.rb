# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration.
# Original: spec/modules/subscription/ping_notification_spec.rb (22 FactoryBot refs, 169 lines).
#
# Blocker for batch A backfill: every example builds `create(:membership_purchase)` or
# `create(:subscription)` + `create(:membership_purchase, subscription:)`. The
# `:membership_purchase` factory is one of the deepest in the codebase — it requires
# a recurring/membership Link (with subscription_duration, tier_category, prices),
# Subscription with PaymentOption + credit_card, ResourceSubscription/license setup
# for the license_key example, and matching original_purchase + recurring purchase
# rows. Skill pitfall references P-subscription-create-blows-up:
# `Subscription.create!` raises "must have at least one PaymentOption" and
# `save!(validate: false)` still crashes on the `update_last_payment_option` callback.
# There are zero `subscriptions:` fixture rows referenced by membership purchases in
# `test/fixtures/`; building one cascades through ≥6 tables (links, prices,
# subscriptions, payment_options, credit_cards, purchases). Out of scope for batch A.
class ModulesSubscriptionPingNotificationTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/modules/subscription/ping_notification_spec.rb — needs full membership_purchase/subscription fixture chain (link+price+payment_option+credit_card+purchase); Subscription.create! / save!(validate: false) both raise on missing PaymentOption per skill pitfall."
  end
end
