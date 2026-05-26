# Checkout edge-case coverage matrix

**Status:** scaffolding live in `test/system/checkout/edge_cases/` — each file holds skip-stubbed Minitest test method per scenario below. Bodies will be filled in incrementally; the test names act as commitments.

**Why a separate directory?** These are the scenarios that produce real production incidents: cross-border tax surprises, 3DS abandonment, card decline edge cases, subscription state weirdness. They live separately from happy-path checkout tests so that:
1. Risk-weighted CI can run them on every PR while happy-path runs on merge.
2. A reviewer touching `app/services/charge/**` sees exactly which edge cases their change affects.
3. Compliance audits (Stripe, EU VAT) have a single directory to point at.

**Test framework:** Playwright + Minitest, base class `SystemTests::SystemTestCase`. No FactoryBot — fixtures or direct `Model.create!`. Stripe-mock pinned via `Stripe.api_base` (never live Stripe).

---

## 1. Cross-border (`cross_border_test.rb`) — 12 tests

The buyer-country × seller-country × card-country matrix. Each test pins one triple and asserts charge currency, tax, display formatting, and any country-specific rule.

| # | Seller | Buyer | Card | Behaviour under test |
|---|---|---|---|---|
| 1 | US | DE | DE | EU VAT applied at checkout, EUR display via multi-currency (#5174). |
| 2 | US | GB | GB | UK VAT (post-Brexit, no longer EU MOSS), GBP display. |
| 3 | US | JP | JP | JPY is zero-decimal — display shows ¥1500 not ¥15.00. |
| 4 | US | IN | IN | RBI SCA mandate triggered, INR display, recurring mandate stored. |
| 5 | US | BR | BR | PIX availability surfaced if seller has it enabled, BRL display. |
| 6 | DE | US | US | Reverse: US buyer pays no EU VAT. Seller's invoice still EU-format. |
| 7 | DE | FR | FR | EU intra-community VAT, place-of-supply rules. |
| 8 | GB | US | US | Post-Brexit GB→US: no VAT, no EU OSS, sterling-denominated seller. |
| 9 | US | AU | AU | Australian GST applied at AUD-converted price. |
| 10 | US | CA | CA | Provincial sales tax (Ontario HST as default; check QC/BC variants). |
| 11 | US | MX | US | Card country ≠ buyer IP country (US expat in Mexico). Tax follows IP. |
| 12 | US | DE | US | Buyer claims DE billing address but pays with US card — anti-fraud signal logged. |

## 2. SCA / 3DS triggers (`sca_test.rb`) — 8 tests

Stripe-mock supports magic card numbers documented at https://stripe.com/docs/testing#regulatory-cards. These flows are silently broken when frontend or webhook plumbing regresses.

1. Card requires 3DS challenge → user completes → purchase succeeds.
2. Card requires 3DS challenge → user abandons mid-challenge → no charge, no purchase row.
3. Indian RBI mandate (32-digit reference number) → success path with mandate stored.
4. Indian mandate → recurring decline on 2nd charge → subscription state flips to `failed_payment`.
5. Off-session subscription renewal triggers SCA → buyer receives email with action link.
6. Saved card + SCA-required transaction (returning customer hits 3DS again).
7. 3DS exemption for low-value transactions (<€30 EUR) → challenge skipped.
8. Soft decline → fall back to no-3DS retry (frictionless flow).

## 3. Card decline & retry paths (`card_decline_test.rb`) — 8 tests

1. Insufficient funds (`4000000000009995`) → decline reason shown to buyer, no purchase row.
2. Stolen card (`4000000000009979`) → silent block, support team gets risk evidence.
3. Expired card → "update card" UX surfaces in checkout.
4. Invalid CVC → inline error before Stripe call (client-side validation).
5. Stripe rate-limit 429 → graceful retry (regression test for the bug seen in PR #5244).
6. Network timeout to Stripe mid-charge → idempotency key prevents double-charge on retry.
7. Stripe webhook delayed by 30s → checkout still completes via `payment_intent.succeeded` polling.
8. Stripe webhook never arrives → polling fallback creates purchase row within 60s.

## 4. Subscription state weirdness (`subscription_lifecycle_test.rb`) — 6 tests

1. First charge succeeds, 2nd charge declines → grace period, automatic retry, then cancel.
2. Subscription paused mid-billing-cycle → no charge at next interval, access retained.
3. Subscription upgraded mid-cycle → prorated charge in BUYER currency (multi-currency, #5174).
4. Subscription with installment plan, payment 2 of 4 fails → no further charges, access removed.
5. Cancel scheduled for end-of-period → access until then, then revoked. Cron job verified.
6. Stripe customer migrated to different account → subscription survives migration, no double-bill.

## 5. Cart edge cases (`cart_edge_test.rb`) — 6 tests

1. Cart with mixed-currency products (multi-currency #5174) → graceful fall back to USD with notice.
2. Cart with one digital + one shipped item → shipping charged once at cart level, not per-line.
3. Cart total = $0 after discount → no Stripe call, purchase row created with `total_cents=0`.
4. Cart total drops below Stripe minimum ($0.50) → blocked with clear error to buyer.
5. Buyer applies discount code, then changes quantity → discount recalculates correctly.
6. Cart abandoned mid-checkout, recovered via email → state preserved on return.

## 6. Tax oddities (`tax_quirks_test.rb`) — 8 tests

1. VAT-exempt B2B EU buyer with valid VATIN → no VAT charged, reverse-charge invoice.
2. VAT-exempt buyer with INVALID VATIN → VAT charged anyway, error logged.
3. US sales tax: buyer in CA (origin-based for in-state) vs NY (destination-based).
4. Reverse-charge mechanism for EU B2B → invoice shows "VAT reverse charged" line.
5. Digital goods VAT under EU OSS (post-2021, replaced VAT-MOSS).
6. US economic nexus: seller crosses $100K in TX → starts collecting TX sales tax on subsequent purchases.
7. Buyer's IP country maps to a different tax jurisdiction (Northern Cyprus → TR or CY?, Puerto Rico → US territory).
8. Tax-inclusive vs tax-exclusive pricing display per locale (DE shows inclusive; US shows exclusive).

## 7. Compliance & risk (`compliance_test.rb`) — 4 tests

1. High-risk MCC (e.g., 5816 digital goods, 7273 dating) → extra Stripe metadata + Radar tags.
2. Seller in OFAC-sanctioned country → checkout blocked at country detection, not at Stripe.
3. Buyer card flagged by Stripe Radar → soft decline + support team notified.
4. Refund within 30 days for declined-card buyer → goes back to original card, not store credit.

---

## Total: 52 edge-case tests across 7 files

| File | Tests | Replaces (approx LOC in existing `spec/requests/`) |
|---|--:|--:|
| `cross_border_test.rb` | 12 | 600 |
| `sca_test.rb` | 8 | 250 |
| `card_decline_test.rb` | 8 | 400 |
| `subscription_lifecycle_test.rb` | 6 | 500 |
| `cart_edge_test.rb` | 6 | 300 |
| `tax_quirks_test.rb` | 8 | 800 |
| `compliance_test.rb` | 4 | 200 |
| **Total** | **52** | **~3,050** |

Projected new LOC: **~1,100** (≈ 65% reduction vs scattered RSpec equivalents).

## Implementation order

1. **Page-object foundation** — `test/system/checkout/checkout_page.rb`. Methods: `goto_product`, `add_to_cart`, `fill_email`, `fill_card(card)`, `submit`, `wait_for_receipt`, `complete_3ds_challenge`, `abandon_3ds_challenge`. Reused across all 52 tests.
2. **Test helpers** — `test/system/checkout/test_helpers.rb`. Fixture seeders: `product_in_currency(USD/EUR/JPY/INR/...)`, `seller_in_country(code)`, `cardholder_with_card(country, magic_number)`.
3. **Stripe-mock card-number constants** — `test/system/checkout/stripe_test_cards.rb`. Map readable names (`INSUFFICIENT_FUNDS`, `REQUIRES_3DS`, etc.) to Stripe magic numbers.
4. **Edge-case files** — scaffolded with skip-stubbed tests carrying the names from this doc.
5. **Body fill-in** — one cluster at a time, smallest-first (compliance → SCA → card decline → cart → subscription → cross-border → tax quirks). Each body is a 15-line Codex job.

## Rules enforced

- One page-object hierarchy. No raw `page.fill` in test files past the foundation.
- Direct `Model.create!` for fixtures — no FactoryBot.
- Each test file ≤ 250 LOC, ≤ 12 tests. Hard limit.
- Locators by role/text, not by CSS class (which churns on React re-renders).
- Stripe-mock only via `Stripe.api_base` pinned in test_helper. Any live-Stripe call is a test bug.
- Each test has a one-line comment naming the production incident class it prevents.
