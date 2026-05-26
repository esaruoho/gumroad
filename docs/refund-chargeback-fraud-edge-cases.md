# Refunds, chargebacks & fraud — edge-case coverage matrix

**Status:** scaffolded in `test/system/checkout/edge_cases/` (this file group is a sibling to the checkout edge cases). 48 tests across 6 files. Each test is skip-stubbed and named for the production-incident class it prevents.

**Why a separate doc/directory?** Refunds, chargebacks, and fraud cluster together because they share the same root system: post-charge money movement. They go wrong differently than checkout (which is about getting money in) — they involve disputes, evidence, regulatory windows, and adversarial actors. The bugs here cause real money loss, not just bad UX.

**Test framework:** Playwright + Minitest. Stripe-mock pinned via `Stripe.api_base`. No FactoryBot — fixtures or direct `Model.create!`. Skip-stub markers describe scenarios; bodies filled in cluster-by-cluster.

---

## 1. Refund happy & rough paths (`refund_test.rb`) — 10 tests

The "buyer wants money back" surface. Most flows are routine but the edges produce 1-star reviews fast.

1. **Buyer requests refund within seller's window** → Stripe refund issued, purchase row marked `refunded`, balance debited. Receipt email sent.
2. **Buyer requests refund outside window** → support routed, no automatic refund. Buyer sees policy text.
3. **Partial refund** ($10 of $50 purchase) → Stripe partial refund, balance debited by $10, purchase row reflects net.
4. **Full refund of subscription mid-period** → access revoked immediately, prorated refund issued.
5. **Refund after seller payout already cleared** → balance can go negative, support flagged for clawback.
6. **Refund in buyer's local currency** (multi-currency #5174) → original currency, not USD-converted, no FX drift loss.
7. **Refund a $0 purchase** (post-discount) → no Stripe call, purchase row updated, audit trail logged.
8. **Refund a card already replaced** (saved card removed by buyer) → routes to original card via Stripe customer ID, succeeds.
9. **Refund a card from closed account** → Stripe returns `card_not_found`, falls back to store credit, support notified.
10. **Multi-refund within 24h** (test for accidental double-refund race) → idempotency key prevents second refund.

## 2. Chargebacks & disputes (`chargeback_test.rb`) — 10 tests

The "buyer's bank claims fraud or wrong product" surface. These hit hard: each chargeback costs $15-25 in fees and erodes Stripe acceptance rate.

1. **Stripe dispute webhook arrives** (`charge.dispute.created`) → dispute row created, seller notified, evidence-submit deadline set.
2. **Auto-submit evidence on dispute** → seller's product description, IP, fulfillment metadata sent to Stripe within 7-day window.
3. **Seller wins dispute** (`charge.dispute.closed` with `status: won`) → balance restored, dispute row marked won.
4. **Seller loses dispute** → balance permanently debited, dispute counts toward chargeback ratio metric.
5. **Dispute withdrawn by buyer** → balance restored same as won, but no chargeback ratio impact.
6. **Pre-arbitration** (second-level dispute) → escalation path, new evidence submission cycle.
7. **Inquiry-only dispute** (Stripe `charge.dispute.created` with `status: warning_needs_response`) → seller responds without losing balance.
8. **Chargeback ratio exceeds Stripe threshold** (1% over 30d) → seller's account flagged for compliance review.
9. **Chargeback on subscription** → only the disputed charge is refunded, subscription stays active or cancels per policy.
10. **Multi-chargeback same buyer** → fraud signal logged, buyer flagged in risk system, future purchases blocked.

## 3. Early fraud warnings (`fraud_warning_test.rb`) — 6 tests

Stripe's `charge.fraud_outcome` + `radar.early_fraud_warning.created` paths. Acting on EFWs avoids ~80% of chargebacks downstream.

1. **EFW received within refund window** → auto-refund issued, support notified, no chargeback occurs.
2. **EFW received outside refund window** → support routed for manual decision, evidence preserved.
3. **EFW marked actionable=false** → no auto-action, just logged.
4. **EFW for subscription** → auto-cancel + refund of disputed charge only, future bills stopped.
5. **EFW followed by chargeback** → confirms decision tree, no double-refund.
6. **EFW for already-refunded purchase** → no-op, idempotency preserves state.

## 4. Risk scoring & seller suspension (`risk_test.rb`) — 8 tests

The active fraud surface — buyers attempting card testing, sellers running pump-and-dumps, abusive refund patterns.

1. **Card testing pattern detected** (5+ failed cards in 60s) → IP blocked, support notified.
2. **Velocity check trips** (10 successful purchases in 1m from same IP) → manual review queue.
3. **High-risk MCC + high cart value** → Radar elevated_risk + manual review.
4. **Repeat refund abuse** (3+ refunds in 30d from same buyer) → buyer flagged, future purchases require additional verification.
5. **Seller pump-and-dump pattern** (large spike in sales from new accounts, all paying with same card pool) → seller suspended, payout held.
6. **Brand impersonation** (product copy matches known brand, seller is new) → flagged for compliance review, optional auto-takedown.
7. **Stolen card test purchase succeeds, dispute follows** → seller balance not credited, dispute auto-conceded.
8. **Low-balance fraud check** (seller balance > payout threshold but seller risk score elevated) → payout held until manual review.

## 5. Seller payouts blocked by money-flow events (`payout_block_test.rb`) — 8 tests

Payouts are downstream of refunds, chargebacks, and fraud. When upstream things go wrong, payouts must be blocked or clawed back.

1. **Pending dispute** → payout held for affected balance until dispute resolves.
2. **Recent chargeback** → 21-day payout hold per fraud-control policy (matches USER.md note).
3. **TOS suspension** → 21-30 day payout hold, then released or refunded depending on outcome.
4. **Compliance hold** (KYC issue) → payout blocked until Stripe verification completes.
5. **Pending refund clawback** (balance went negative from refund after payout cleared) → next payout reduced.
6. **Mass refund event** (e.g., product fraud requires bulk refunds) → all related payouts held, balance reconciled.
7. **Stripe Connect account in review** → payout held even if Gumroad would allow it.
8. **Seller country sanctions change** (OFAC update) → existing balance held, future sales blocked.

## 6. Cross-cutting compliance & accounting (`refund_compliance_test.rb`) — 6 tests

These touch finance + compliance teams. They produce audit findings if they regress.

1. **VAT refund on EU sale** → VAT portion refunded back to buyer, not seller balance, VAT reporting updated.
2. **1099-K threshold edge** ($600+ in sales but high refund volume drops net below threshold) → 1099-K not issued.
3. **Refund crosses month boundary** → accounting books refund in original sale month, not refund month, for revenue recognition.
4. **Refund of installment plan** → only paid installments refunded, future installments cancelled.
5. **Refund + currency exchange rate drift** → refund issued at original rate, no FX loss to buyer; Gumroad bears any drift.
6. **GDPR data deletion request** for buyer with active disputes → purchase data retained for dispute window, anonymized otherwise.

---

## Total: 48 tests across 6 files

| File | Tests | Replaces (approx LOC in existing specs) |
|---|--:|--:|
| `refund_test.rb` | 10 | ~600 (scattered across purchase_refunds_spec, refund_spec, balance_pages_spec) |
| `chargeback_test.rb` | 10 | ~500 (dispute_evidence_spec + dispute_spec + fight_dispute_job) |
| `fraud_warning_test.rb` | 6 | ~300 (process_early_fraud_warning_job + early_fraud_warning_spec) |
| `risk_test.rb` | 8 | ~600 (block_stripe_suspected_fraudulent_payments_worker + admin/users + mass_refund_for_fraud_job) |
| `payout_block_test.rb` | 8 | ~400 (refund_unpaid_purchases_worker + balance/refund_eligibility_underwriter + low_balance_fraud_check) |
| `refund_compliance_test.rb` | 6 | ~300 (purchase_refund_policy + seller_refund_policy + product_refund_policy) |
| **Total** | **48** | **~2,700** |

Projected new LOC: **~1,200** (≈ 55% reduction vs scattered RSpec equivalents).

## Implementation order

1. **Stripe webhook fixture helpers** (`test/system/checkout/stripe_webhook_fixtures.rb`) — generate signed `charge.refunded`, `charge.dispute.created`, `radar.early_fraud_warning.created` payloads. Reused across all 48 tests.
2. **Risk fixture seeders** (`test/system/checkout/risk_fixtures.rb`) — card-testing patterns, velocity-trip seeds, repeat-refund-abuse buyer.
3. **Smallest cluster first:** `refund_compliance_test.rb` (6) → `fraud_warning_test.rb` (6) → `cart-edge-style straightforward` clusters → end with `risk_test.rb` which needs deepest fixture work.

## Rules enforced

- Each test names the **production-incident class** it prevents in a one-line comment above the test.
- Each test asserts **at least one accounting invariant** (balance changed by correct amount, dispute row created, payout held).
- Stripe-mock only via `Stripe.api_base`. Webhooks are constructed with `Stripe::Webhook.generate_test_header_string` (see MEMORY.md notes on Stripe testing).
- No FactoryBot. Fixtures + `Model.create!`.
- Each test file ≤ 300 LOC, ≤ 12 tests (slightly higher than checkout edge cases — accounting setups are more verbose).
