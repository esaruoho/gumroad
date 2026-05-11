# Stripe Radar Integration — Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Surface Stripe Radar signals (risk scores, early fraud warnings, dispute predictions) in Gumroad's admin/risk UI and use them to auto-flag or auto-suspend sellers.

**Architecture:** Persist `outcome.risk_level` on every charge (standard Radar — no Fraud Teams). Aggregate per-seller Radar signals into a risk profile shown in admin. Auto-flag sellers who cross configurable thresholds. Feed Gumroad's blocked buyers/sellers back to Stripe via Radar value lists.

**Note:** We use standard Radar (free), not Radar for Fraud Teams ($0.07/txn). This means: no numeric `risk_score` (0-99), no `review.opened/closed` events, no custom rule predicates. We work with `risk_level` (normal/elevated/highest) only.

**Tech Stack:** Rails 8, Stripe API (v2025+), Inertia/React admin UI, Sidekiq jobs

---

## Audit Summary — What Exists Today

### Already working
- `radar.early_fraud_warning.created/updated` → `StripeChargeRadarProcessor` → `EarlyFraudWarning` model → `ProcessEarlyFraudWarningJob` (auto-refunds actionable fraud)
- `charge.dispute.*` → full dispute lifecycle (formalize → fight → win/lost)
- `charge.outcome.risk_level` extracted in `StripeCharge` but **not persisted** on Purchase/Charge
- Buyer-side auto-blocking: card testing detection, fraudulent decline auto-suspend, chargeback count blocking
- Seller-side auto-probation: balance < -$100
- Seller risk state machine: `not_reviewed → compliant/on_probation/flagged/suspended`
- WatchedUser model for manual watchlist
- Internal admin API with full user/purchase/payout management
- Admin UI: risk state, suspend for fraud, watchlist, unreviewed queue

### Gaps (what this plan builds)
1. **`outcome.risk_level` not persisted** — we capture it in `StripeCharge` but discard it, never stored on Charge records
2. **No per-seller risk aggregation** — no way to see "this seller's buyers have 40% elevated+ charges"
3. **No auto-flag from Radar signals** — sellers accumulating high-risk charges don't get flagged automatically
4. **No Radar signals in admin UI** — reviewers don't see risk levels, EFW history, or charge outcomes
5. **No Stripe value list sync** — Gumroad's blocked buyers aren't pushed to Stripe Radar
6. **No data to evaluate "maximize protection"** — can't project false positive impact without persisted risk levels

---

## Phase 1: Persist Radar Data on Charges

### Task 1: Add risk columns to charges table

**Objective:** Store `outcome.risk_level` and `outcome.risk_score` on every charge

**Files:**
- Create: `db/migrate/XXXX_add_radar_fields_to_charges.rb`
- Modify: `app/models/charge.rb`

```ruby
# Migration
class AddRadarFieldsToCharges < ActiveRecord::Migration[8.0]
  def change
    add_column :charges, :stripe_risk_level, :string
    add_column :charges, :stripe_outcome_type, :string
    add_column :charges, :stripe_outcome_reason, :string
    add_index :charges, :stripe_risk_level
  end
end
```

**Verification:** `rails db:migrate` succeeds, `Charge.column_names` includes new fields

### Task 2: Populate risk fields when charges are created

**Objective:** Extract Radar outcome data from Stripe charge objects and persist it

**Files:**
- Modify: `app/business/payments/charging/implementations/stripe/stripe_charge.rb`
- Modify: wherever `Charge` records are created from Stripe responses

Find where `StripeCharge` maps Stripe data → Gumroad fields. Add:
```ruby
charge.stripe_risk_level = stripe_charge.outcome&.risk_level
charge.stripe_outcome_type = stripe_charge.outcome&.type
charge.stripe_outcome_reason = stripe_charge.outcome&.reason
```

**Verification:** Create a test charge in Stripe test mode, confirm `Charge.last.stripe_risk_level` is populated

### Task 3: Backfill risk data for recent charges

**Objective:** Populate risk fields for last 90 days of charges from Stripe API

**Files:**
- Create: `app/sidekiq/backfill_charge_radar_data_job.rb`

```ruby
class BackfillChargeRadarDataJob
  include Sidekiq::Job
  sidekiq_options queue: :low_priority

  def perform(charge_id)
    charge = Charge.find(charge_id)
    return if charge.stripe_risk_level.present?
    return unless charge.stripe_transaction_id.present?

    stripe_charge = Stripe::Charge.retrieve(charge.stripe_transaction_id)
    charge.update!(
      stripe_risk_level: stripe_charge.outcome&.risk_level,
      stripe_outcome_type: stripe_charge.outcome&.type,
      stripe_outcome_reason: stripe_charge.outcome&.reason
    )
  end
end
```

Run via: `Charge.where(stripe_risk_level: nil).where("created_at > ?", 90.days.ago).find_each { |c| BackfillChargeRadarDataJob.perform_async(c.id) }`

---

## Phase 2: Per-Seller Risk Aggregation

### Task 4: Add seller risk stats service

**Objective:** Compute per-seller Radar risk stats: % elevated charges, % highest charges, EFW count, dispute rate

**Files:**
- Create: `app/services/radar/seller_risk_stats_service.rb`

```ruby
module Radar
  class SellerRiskStatsService
    def initialize(user)
      @user = user
    end

    def stats(period: 90.days)
      charges = @user.charges.where("created_at > ?", period.ago)
      total = charges.count
      return {} if total.zero?

      {
        total_charges: total,
        elevated_count: charges.where(stripe_risk_level: "elevated").count,
        highest_count: charges.where(stripe_risk_level: "highest").count,
        elevated_pct: (charges.where(stripe_risk_level: "elevated").count * 100.0 / total).round(1),
        highest_pct: (charges.where(stripe_risk_level: "highest").count * 100.0 / total).round(1),
        efw_count: @user.purchases.joins(:early_fraud_warning).where("purchases.created_at > ?", period.ago).count,
        dispute_count: @user.disputes.where("created_at > ?", period.ago).count,
        dispute_rate: (@user.disputes.where("created_at > ?", period.ago).count * 100.0 / total).round(2)
      }
    end
  end
end
```

**Verification:** `Radar::SellerRiskStatsService.new(User.find(X)).stats` returns populated hash

### Task 5: Auto-flag sellers based on Radar thresholds

**Objective:** Automatically flag sellers when their Radar stats exceed thresholds

**Files:**
- Create: `app/sidekiq/radar/check_seller_risk_job.rb`

```ruby
module Radar
  class CheckSellerRiskJob
    include Sidekiq::Job
    sidekiq_options queue: :default

    # Configurable thresholds
    ELEVATED_PCT_THRESHOLD = 20  # >20% elevated charges → flag
    HIGHEST_PCT_THRESHOLD = 5   # >5% highest charges → flag
    EFW_COUNT_THRESHOLD = 3     # 3+ EFWs in 90 days → flag
    DISPUTE_RATE_THRESHOLD = 1  # >1% dispute rate → flag

    def perform(user_id)
      user = User.find(user_id)
      return unless user.user_risk_state.in?(%w[not_reviewed compliant])

      stats = SellerRiskStatsService.new(user).stats
      return if stats[:total_charges].to_i < 10  # skip low-volume

      reasons = []
      reasons << "#{stats[:elevated_pct]}% elevated-risk charges" if stats[:elevated_pct] > ELEVATED_PCT_THRESHOLD
      reasons << "#{stats[:highest_pct]}% highest-risk charges" if stats[:highest_pct] > HIGHEST_PCT_THRESHOLD
      reasons << "#{stats[:efw_count]} early fraud warnings" if stats[:efw_count] >= EFW_COUNT_THRESHOLD
      reasons << "#{stats[:dispute_rate]}% dispute rate" if stats[:dispute_rate] > DISPUTE_RATE_THRESHOLD

      return if reasons.empty?

      user.flag_for_fraud!
      user.add_comment(
        author_name: "radar_auto_flag",
        content: "Auto-flagged by Radar signals (90d): #{reasons.join(', ')}. Stats: #{stats.inspect}"
      )
    end
  end
end
```

Trigger: run after each charge via `charge.succeeded` event, or on a daily cron for all sellers with recent charges.

**Verification:** Create seller with test charges above threshold, run job, confirm state changes to `flagged_for_fraud`

---

## Phase 3: Surface Radar Signals in Admin UI

### Task 6: Add Radar stats to admin user presenter

**Objective:** Include Radar risk stats in the admin user card

**Files:**
- Modify: `app/presenters/admin/user_presenter/card.rb`

Add to the presenter hash:
```ruby
radar_stats: Radar::SellerRiskStatsService.new(user).stats,
recent_efws: user.purchases.joins(:early_fraud_warning)
  .order(created_at: :desc).limit(5)
  .map { |p| { purchase_id: p.external_id, fraud_type: p.early_fraud_warning.fraud_type, risk_level: p.early_fraud_warning.charge_risk_level, created_at: p.early_fraud_warning.created_at } },
```

### Task 7: Build Radar signals panel in admin UI

**Objective:** Show Radar stats, EFW history, and risk score distribution in the admin user page

**Files:**
- Create: `app/javascript/components/Admin/Users/PermissionRisk/RadarSignals.tsx`
- Modify: `app/javascript/components/Admin/Users/PermissionRisk/index.tsx`

Component shows:
- Risk level distribution bar (normal/elevated/highest)
- EFW count with fraud types
- Dispute rate
- Color-coded thresholds (green/yellow/red)

### Task 8: Add risk level to admin purchase search results

**Objective:** Show Stripe risk level in purchase search results in admin

**Files:**
- Modify: `app/controllers/admin/search/purchases_controller.rb` or relevant presenter
- Modify: admin purchases search UI component

Add `stripe_risk_level` to purchase search result cards.

---

## Phase 4: Sync Gumroad Blocks → Stripe Radar Value Lists

### Task 9: Create Stripe Radar value list sync service

**Objective:** Push Gumroad's blocked buyers (emails, card fingerprints) to Stripe Radar block lists so Radar rules can reference them

**Files:**
- Create: `app/services/radar/value_list_sync_service.rb`
- Create: `app/sidekiq/radar/sync_value_lists_job.rb`

```ruby
module Radar
  class ValueListSyncService
    BLOCKED_EMAILS_LIST = "gumroad_blocked_emails"
    BLOCKED_CARDS_LIST = "gumroad_blocked_cards"

    def sync_blocked_emails
      list = find_or_create_list(BLOCKED_EMAILS_LIST, "email")
      BlockedObject.where(object_type: "email").where("created_at > ?", 1.day.ago).find_each do |bo|
        Stripe::Radar::ValueListItem.create(value_list: list.id, value: bo.object_value)
      rescue Stripe::InvalidRequestError => e
        # Already exists, skip
        raise unless e.message.include?("already exists")
      end
    end

    def sync_blocked_cards
      list = find_or_create_list(BLOCKED_CARDS_LIST, "card_fingerprint")
      BlockedObject.where(object_type: "stripe_fingerprint").where("created_at > ?", 1.day.ago).find_each do |bo|
        Stripe::Radar::ValueListItem.create(value_list: list.id, value: bo.object_value)
      rescue Stripe::InvalidRequestError => e
        raise unless e.message.include?("already exists")
      end
    end

    private

    def find_or_create_list(alias_name, item_type)
      Stripe::Radar::ValueList.retrieve(alias_name)
    rescue Stripe::InvalidRequestError
      Stripe::Radar::ValueList.create(alias: alias_name, name: alias_name.titleize, item_type: item_type)
    end
  end
end
```

Then create Radar rules in Stripe Dashboard:
- `Block if ::is_blocked::` (using `gumroad_blocked_emails` list)
- `Block if :card_fingerprint: in ::gumroad_blocked_cards::`

**Verification:** Block a test email in Gumroad, run sync, confirm it appears in Stripe Radar value list via Dashboard

---

## Execution Order

| Phase | Tasks | Deps | Est. |
|-------|-------|------|------|
| 1. Persist Radar data | 1-3 | None | 1 day |
| 2. Risk aggregation | 4-5 | Phase 1 | 0.5 day |
| 3. Admin UI | 6-8 | Phases 1-2 | 1 day |
| 4. Value list sync | 9 | None (independent) | 0.5 day |

**Total: ~3 days of focused work**

Phases 1+4 can run in parallel.

---

## Open Questions

1. **Auto-flag vs auto-suspend?** Plan uses auto-flag (human reviews before suspension). Could auto-suspend for extreme thresholds (e.g., >10% highest-risk charges).
2. **Threshold tuning** — The constants in Task 5 are starting points. Adjust based on actual data after backfill.
