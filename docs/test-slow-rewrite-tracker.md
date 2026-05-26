# Test Slow → Playwright Minitest rewrite tracker

Live checklist for [PR #5240](https://github.com/antiwork/gumroad/pull/5240). Every test below is a Minitest stub in `test/system/`. As bodies fill in, tick the checkbox.

**Rules** (enforced cluster-wide):
- No FactoryBot — Rails YAML fixtures or `Model.create!`.
- One page-object hierarchy. No raw `page.fill` in test bodies past the foundation.
- Stripe-mock only. `Stripe.api_base` pinned in `test_helper.rb`.
- Each test names the production-incident class it prevents in a one-line comment above the test.
- Each test file ≤ 300 LOC, ≤ 12 tests.
- Locators target role/text, not CSS classes.

## Totals

- **Files:** 53
- **Tests scaffolded:** 304
- **Tests filled:** 16 / 304 (5.3%)
- **Tests stubbed (skip-only):** 288

## Cluster summary

| Cluster | Files | Tests | Filled | % |
|---|--:|--:|--:|--:|
| Auth (login/signup/password/2FA/smoke) | 5 | 16 | 16 / 16 | 100% |
| Checkout main flows | 7 | 90 | 48 / 90 | 53% |
| Edge cases (checkout + refund/chargeback/fraud) | 13 | 100 | 0 / 100 | 0% |
| Product types | 6 | 34 | 0 / 34 | 0% |
| Affiliate & collaborator | 2 | 10 | 0 / 10 | 0% |
| Buyer account & library | 2 | 10 | 0 / 10 | 0% |
| Seller flows | 6 | 29 | 0 / 29 | 0% |
| API & webhooks | 4 | 22 | 0 / 22 | 0% |
| Communication (emails) | 3 | 14 | 0 / 14 | 0% |
| Admin tools | 2 | 8 | 0 / 8 | 0% |
| Concurrency & race conditions | 1 | 5 | 0 / 5 | 0% |
| Discovery & search | 1 | 5 | 0 / 5 | 0% |
| Embed (overlay/iframe) | 1 | 4 | 0 / 4 | 0% |
| Security & abuse | 1 | 5 | 0 / 5 | 0% |

## Auth (login/signup/password/2FA/smoke)  (16 / 16)

### `test/system/login_test.rb` (6 / 6)

- [x] `test_existing_user_signs_in_successfully`
- [x] `test_wrong_password_redirects_back_to_login`
- [x] `test_next_param_is_honored_after_successful_login`
- [x] `test_logout_destroys_the_session`
- [x] `test_suspended_for_tos_user_signs_in_without_error`
- [x] `test_deleted_user_cannot_sign_in`

### `test/system/password_reset_test.rb` (2 / 2)

- [x] `test_request_reset_for_existing_user_redirects_to_login`
- [x] `test_request_reset_for_unknown_email_stays_on_forgot_password`

### `test/system/signup_test.rb` (4 / 4)

- [x] `test_new_user_signs_up_successfully`
- [x] `test_signup_with_existing_email_redirects_back_with_error`
- [x] `test_referrer_query_string_signup_accepts_form`
- [x] `test_next_param_is_honored_after_successful_signup`

### `test/system/smoke_test.rb` (1 / 1)

- [x] `test_healthcheck_returns_ok`

### `test/system/two_factor_authentication_test.rb` (3 / 3)

- [x] `test_login_for_2fa_user_redirects_to_two_factor_challenge`
- [x] `test_wrong_token_keeps_user_on_two_factor`
- [x] `test_resend_token_button_stays_on_two_factor`


## Checkout main flows  (48 / 90)

### `test/system/checkout/apple_google_pay_test.rb` (0 / 6)

- [ ] `test_apple_pay_button_displays_on_supported_device` — _Button missing on Safari/iOS, buyer abandons_
- [ ] `test_apple_pay_purchase_succeeds_no_3ds` — _Apple Pay bypasses 3DS but our flow forces it, conversion lost_
- [ ] `test_google_pay_button_displays_on_supported_device` — _Button missing in Chrome on Android_
- [ ] `test_google_pay_purchase_succeeds` — _Google Pay completes but no purchase row created_
- [ ] `test_apple_pay_handles_subscription_correctly` — _Apple Pay subscription mandate not stored; recurring fails_
- [ ] `test_apple_pay_billing_address_synced` — _Address from Apple Pay not synced; shipping label fails_

### `test/system/checkout/bundle_test.rb` (0 / 6)

- [ ] `test_bundle_purchase_grants_access_to_all_included_products` — _Bundle purchase only grants partial access; buyer support burst_
- [ ] `test_bundle_with_discount_applies_to_bundle_total_not_per_product` — _Discount applied per-product, oversells the discount value_
- [ ] `test_partial_refund_of_bundle_only_revokes_refunded_product` — _Refund revokes all bundle access; rest of products lost too_
- [ ] `test_bundle_pricing_locks_at_purchase_time` — _Bundle composition change post-purchase changes buyer's grants_
- [ ] `test_bundle_with_subscription_inside_charges_subscription_separately` — _Bundle subscription billing schedule corrupted at purchase_
- [ ] `test_bundle_with_mixed_currency_components_falls_back_to_seller_currency` — _Mixed-currency bundle crashes at checkout_

### `test/system/checkout/cart_test.rb` (0 / 6)

- [ ] `test_add_two_products_to_cart_checkout_charges_both_sellers` — _Universal Cart charge fails to split correctly between sellers_
- [ ] `test_remove_item_from_cart_recomputes_total` — _Removed item still charged; buyer sees ghost line item_
- [ ] `test_change_quantity_in_cart_persists` — _Quantity change reset on page reload; buyer abandons_
- [ ] `test_cart_persists_across_session` — _Cart cleared when session refreshed; buyer loses items, abandons_
- [ ] `test_cart_with_subscription_plus_one_time` — _Mixed cart fails on subscription validation, blocks one-time purchase too_
- [ ] `test_empty_cart_redirects_back_to_discover` — _Empty cart URL crashes instead of redirecting_

### `test/system/checkout/core_checkout_test.rb` (0 / 8)

- [ ] `test_digital_product_visa_us_buyer_succeeds` — _Happy-path checkout broken silently — every other test is built on this passing_
- [ ] `test_digital_product_logged_in_user_succeeds` — _Logged-in checkout bypasses session-aware billing logic_
- [ ] `test_digital_product_guest_then_signup_succeeds` — _Post-purchase signup link broken, buyer never gets library access_
- [ ] `test_display_total_matches_charge_amount` — _Display total != Stripe charge — buyer-facing UX bug surfaces as billing complaint_
- [ ] `test_receipt_email_sent_after_success` — _Receipt email never sent; buyer thinks purchase failed_
- [ ] `test_download_link_works_immediately` — _Library row created but download URL not pre-signed; buyer hits 404_
- [ ] `test_multi_quantity_purchase` — _Quantity multiplier ignored at Stripe level; buyer charged for 1 of 3_
- [ ] `test_custom_field_captured_on_purchase` — _Required custom field skipped; seller misses fulfillment info_

### `test/system/checkout/discount_test.rb` (0 / 10)

- [ ] `test_percent_off_discount_applies_to_total_before_tax` — _Discount applied after tax; oversells discount value_
- [ ] `test_fixed_amount_discount_in_seller_currency` — _Fixed discount in wrong currency; buyer overcharged or undercharged_
- [ ] `test_offer_code_usage_limit_blocks_after_n_uses` — _Usage limit ignored; promo bleeds revenue_
- [ ] `test_expired_offer_code_rejected` — _Expired code accepted; revenue loss_
- [ ] `test_offer_code_per_buyer_cap` — _Per-buyer cap ignored; one buyer drains the promo_
- [ ] `test_stacking_two_offer_codes_disallowed` — _Stacking allowed silently; oversells_
- [ ] `test_default_discount_code_auto_applied` — _Auto-apply broken; promo never reaches buyers_
- [ ] `test_zero_discount_does_not_skip_validation` — _Zero discount bypasses checkout validation; corrupt purchase row_
- [ ] `test_invalid_offer_code_shows_clear_error` — _Invalid code returns 500; buyer abandons_
- [ ] `test_offer_code_with_tiered_membership_applies_to_correct_tier` — _Tier discount applied to wrong tier price_

### `test/system/checkout/upsell_test.rb` (0 / 6)

- [ ] `test_upsell_offered_after_main_purchase` — _Upsell never shown; conversion revenue lost silently_
- [ ] `test_upsell_accepted_charges_saved_card_immediately` — _Upsell creates separate intent; UX shows 'pay again'_
- [ ] `test_upsell_declined_does_not_charge` — _Decline path creates charge anyway; double-bill_
- [ ] `test_upsell_with_offer_code_applies_discount` — _Offer code ignored on upsell; buyer paid full price_
- [ ] `test_upsell_after_subscription_purchase_works` — _Upsell crashes when main was subscription_
- [ ] `test_upsell_cross_seller_blocked` — _Cross-seller upsell crosses Universal Cart boundaries unsafely_


## Tax display rewrite

`test/system/checkout/tax_display_test.rb` replaces the monolithic `spec/requests/purchases/product/taxes_spec.rb` coverage for buyer-facing checkout tax display. It keeps the old spec in place for this PR, but rewrites the Test Slow surface as one Playwright file focused on the checkout tax line, total, VAT/GST copy, VATIN reverse charge, country changes, variant/tier recomputation, and persisted purchase tax fields.

### `test/system/checkout/tax_display_test.rb` (48 / 48)

- [x] `test_us_sales_tax_az_zip_physical_product`
- [x] `test_us_sales_tax_ny_zip_physical_product`
- [x] `test_us_no_nexus_state_mt_shows_no_tax_line`
- [x] `test_eu_buyer_de_digital_product_vat`
- [x] `test_eu_buyer_de_with_valid_vatin_reverse_charges_vat`
- [x] `test_uk_buyer_post_brexit_digital_product_vat`
- [x] `test_india_buyer_digital_product_igst`
- [x] `test_australia_gst`
- [x] `test_singapore_gst`
- [x] `test_norway_tax`
- [x] `test_japan_jct`
- [x] `test_new_zealand_gst`
- [x] `test_canada_on_gst_hst`
- [x] Country tax matrix — 29 generated country-specific tests from `COUNTRY_TAX_CASES`
- [x] `test_country_change_recomputes_tax`
- [x] `test_variant_price_difference_recomputes_tax`
- [x] `test_tiered_membership_tax`
- [x] `test_tax_inclusive_and_exclusive_checkout_copy`
- [x] `test_collect_eu_vat_seller_flag_keeps_marketplace_vat_displayed`
- [x] `test_vatin_field_appears_only_for_taxable_countries_that_accept_business_ids`


## Edge cases (checkout + refund/chargeback/fraud)  (0 / 100)

### `test/system/checkout/edge_cases/card_decline_test.rb` (0 / 8)

- [ ] `test_insufficient_funds_shows_specific_decline_reason` — _Buyer sees generic "card declined" with no actionable detail_
- [ ] `test_stolen_card_silent_block_logs_risk_evidence` — _Stolen card decline returned as generic error, support misses signal_
- [ ] `test_expired_card_surfaces_update_card_prompt` — _Expired card error doesn't surface "update card" prompt_
- [ ] `test_invalid_cvc_caught_before_stripe_call` — _Invalid CVC triggers Stripe call instead of client-side rejection_
- [ ] `test_stripe_rate_limit_429_retries_gracefully` — _stripe-mock 429 (or real rate limit) propagates as 500 to buyer_
- [ ] `test_network_timeout_idempotency_key_prevents_double_charge` — _Network blip causes double-charge because idempotency key wasn't used_
- [ ] `test_webhook_delayed_30s_polling_completes_checkout` — _Webhook delay leaves buyer on spinner forever_
- [ ] `test_webhook_never_arrives_polling_fallback_creates_purchase` — _Webhook never arrives, purchase orphaned with intent_succeeded but no row_

### `test/system/checkout/edge_cases/cart_edge_test.rb` (0 / 6)

- [ ] `test_mixed_currency_cart_falls_back_to_usd_with_notice` — _Mixed-currency cart crashes checkout instead of degrading gracefully_
- [ ] `test_digital_plus_shipped_cart_shipping_charged_once` — _Shipping charged per line-item instead of once per cart_
- [ ] `test_zero_total_cart_no_stripe_call_creates_zero_purchase` — _$0 cart still calls Stripe, leaving orphaned payment intent_
- [ ] `test_below_stripe_minimum_blocked_with_clear_error` — _$0.30 cart hits Stripe minimum and shows obscure 500 error_
- [ ] `test_discount_then_quantity_change_recalculates_correctly` — _Quantity change applies stale discount, buyer overcharged_
- [ ] `test_abandoned_cart_recovered_state_preserved` — _Abandoned cart recovered via email but state lost, buyer re-enters everything_

### `test/system/checkout/edge_cases/chargeback_test.rb` (0 / 10)

- [ ] `test_stripe_dispute_created_webhook_creates_dispute_row` — _Dispute webhook arrives but no row created, evidence deadline missed_
- [ ] `test_auto_submit_evidence_within_7_day_window` — _Evidence not auto-submitted within 7-day window, default loss_
- [ ] `test_dispute_won_balance_restored` — _Won dispute balance not restored_
- [ ] `test_dispute_lost_balance_debited_chargeback_ratio_incremented` — _Lost dispute balance not debited, Gumroad books wrong revenue_
- [ ] `test_dispute_withdrawn_balance_restored_no_ratio_impact` — _Buyer-withdrawn dispute treated as loss, balance not restored_
- [ ] `test_pre_arbitration_escalation_new_evidence_cycle` — _Pre-arbitration escalation missed, no evidence resubmitted_
- [ ] `test_inquiry_only_dispute_response_no_balance_hit` — _Inquiry-only dispute treated as full chargeback, balance hit unnecessarily_
- [ ] `test_chargeback_ratio_exceeds_threshold_flags_account_review` — _Stripe acceptance threshold crossed silently, account terminated_
- [ ] `test_subscription_chargeback_only_disputed_charge_refunded` — _Chargeback on subscription cancels entire history, double-refunds_
- [ ] `test_multi_chargeback_same_buyer_flags_fraud_blocks_future_purchases` — _Repeat-chargeback buyer reuses Gumroad freely, future fraud unblocked_

### `test/system/checkout/edge_cases/compliance_test.rb` (0 / 4)

- [ ] `test_high_risk_mcc_5816_digital_goods_metadata_tagged` — _High-risk MCC stripped from Stripe metadata, Radar can't score_
- [ ] `test_ofac_sanctioned_country_blocked_at_country_detection` — _OFAC-sanctioned country reaches Stripe, triggering account-level audit_
- [ ] `test_radar_flagged_card_soft_decline_notifies_support` — _Radar-flagged card silently charged, no support notification_
- [ ] `test_refund_within_30_days_routes_to_original_card_not_store_credit` — _Refund issued as store credit despite buyer's card being declined later_

### `test/system/checkout/edge_cases/cross_border_test.rb` (0 / 12)

- [ ] `test_us_seller_de_buyer_charged_in_eur_with_vat` — _EU buyer charged in USD, VAT applied at wrong rate_
- [ ] `test_us_seller_gb_buyer_charged_in_gbp_post_brexit_vat` — _GBP-denominated checkout still showing USD_
- [ ] `test_us_seller_jp_buyer_jpy_zero_decimal_display` — _JPY displayed with two decimals (¥1500.00 instead of ¥1500)_
- [ ] `test_us_seller_in_buyer_rbi_sca_mandate_stored` — _Indian buyer missing RBI mandate, recurring fails_
- [ ] `test_us_seller_br_buyer_pix_offered_when_seller_enabled` — _BRL price displayed but PIX unavailable, buyer abandons_
- [ ] `test_de_seller_us_buyer_no_vat_on_us_destination` — _US buyer charged EU VAT they should never see_
- [ ] `test_de_seller_fr_buyer_eu_intra_community_vat` — _EU intra-community VAT charged twice_
- [ ] `test_gb_seller_us_buyer_no_eu_oss_post_brexit` — _Post-Brexit GB seller still using EU OSS plumbing_
- [ ] `test_us_seller_au_buyer_gst_on_audconverted_price` — _AUD-converted price missing GST_
- [ ] `test_us_seller_ca_buyer_on_hst_applied` — _Provincial sales tax (ON HST) not applied_
- [ ] `test_us_seller_us_card_mx_ip_tax_follows_ip` — _Tax follows card country instead of IP, EU expat in MX taxed wrong_
- [ ] `test_us_seller_us_card_de_billing_logs_mismatch_for_fraud_review` — _Buyer spoofs EU billing address with US card, no anti-fraud signal_

### `test/system/checkout/edge_cases/fraud_warning_test.rb` (0 / 6)

- [ ] `test_efw_in_window_auto_refunds_notifies_support` — _EFW arrives in window but no auto-refund, chargeback follows next week_
- [ ] `test_efw_outside_window_routes_to_support_no_auto_action` — _EFW outside window auto-acted-on against policy_
- [ ] `test_efw_actionable_false_no_op_logs_only` — _Non-actionable EFW triggers refund anyway, false positive cost_
- [ ] `test_efw_subscription_auto_cancels_refunds_only_disputed_charge` — _Subscription EFW cancels all history, double-refunds_
- [ ] `test_efw_then_chargeback_no_double_refund` — _EFW followed by chargeback causes double-refund_
- [ ] `test_efw_on_already_refunded_purchase_no_op` — _EFW on already-refunded purchase issues second refund_

### `test/system/checkout/edge_cases/payout_block_test.rb` (0 / 8)

- [ ] `test_pending_dispute_holds_affected_balance_in_payout` — _Pending dispute paid out, then dispute lost — Gumroad eats the loss_
- [ ] `test_recent_chargeback_triggers_21_day_payout_hold` — _Recent chargeback bypasses 21-day hold, balance paid out and clawed back_
- [ ] `test_tos_suspension_holds_payout_21_to_30_days` — _TOS suspended seller paid out anyway, support manually unwinding_
- [ ] `test_kyc_compliance_hold_blocks_payout_pending_verification` — _KYC-incomplete seller paid out, Stripe Connect flags account_
- [ ] `test_pending_refund_clawback_reduces_next_payout` — _Negative-balance seller paid out next cycle anyway, debt compounds_
- [ ] `test_mass_refund_event_holds_all_related_payouts` — _Mass refund event paid out before balance reconciled, double loss_
- [ ] `test_stripe_connect_under_review_blocks_payout` — _Stripe Connect under review but Gumroad pays out anyway, Stripe debit_
- [ ] `test_seller_country_sanctions_change_holds_balance_blocks_sales` — _OFAC list update makes existing seller sanctioned, payout still released_

### `test/system/checkout/edge_cases/refund_compliance_test.rb` (0 / 6)

- [ ] `test_eu_vat_refund_returned_to_buyer_not_debited_from_seller_balance` — _VAT portion of refund debited from seller balance, VAT reporting wrong_
- [ ] `test_1099k_threshold_uses_net_of_refunds` — _1099-K filed for seller below net threshold due to refunds, IRS amendment burden_
- [ ] `test_refund_crosses_month_boundary_books_in_original_sale_month` — _Refund booked in refund month, revenue recognition fails GAAP audit_
- [ ] `test_installment_plan_refund_only_paid_installments_cancels_future` — _Installment plan refunded across all installments, future ones still charged_
- [ ] `test_refund_at_original_fx_rate_gumroad_bears_drift` — _FX drift on refund eats buyer balance, perceived as overcharge_
- [ ] `test_gdpr_deletion_with_active_dispute_retains_until_resolved` — _GDPR deletion strips dispute evidence before window closes, default loss_

### `test/system/checkout/edge_cases/refund_test.rb` (0 / 10)

- [ ] `test_refund_within_window_issues_stripe_refund_debits_balance` — _Refund issued but Stripe charge not refunded, buyer charges back instead_
- [ ] `test_refund_outside_window_routes_to_support_no_auto_refund` — _Refund silently issued past policy window, seller blindsided_
- [ ] `test_partial_refund_debits_balance_by_partial_amount` — _Partial refund double-charges balance for the unrefunded portion_
- [ ] `test_subscription_mid_period_refund_revokes_access_prorates_refund` — _Subscription mid-period refund leaves access intact, buyer keeps content for free_
- [ ] `test_refund_after_payout_cleared_flags_balance_for_clawback` — _Negative balance from post-payout refund never clawed back, Gumroad eats the loss_
- [ ] `test_refund_in_buyer_local_currency_no_fx_drift` — _Multi-currency refund converted to USD, buyer loses FX delta_
- [ ] `test_refund_of_zero_total_purchase_no_stripe_call_audit_trail_logged` — _$0 purchase refund triggers Stripe call, orphaned refund row_
- [ ] `test_refund_with_replaced_card_routes_via_customer_id` — _Buyer removed card after purchase, refund silently fails_
- [ ] `test_refund_to_closed_account_falls_back_to_store_credit` — _Refund to closed account fails silently, no fallback_
- [ ] `test_multi_refund_within_24h_idempotency_key_prevents_double` — _Race condition double-refunds, support manually clawing back_

### `test/system/checkout/edge_cases/risk_test.rb` (0 / 8)

- [ ] `test_card_testing_pattern_5_failed_cards_60s_blocks_ip` — _Card testing pattern unblocked, Stripe issues account warning_
- [ ] `test_velocity_check_10_purchases_1m_routes_to_review` — _Velocity check disabled, bot scrapes purchases through_
- [ ] `test_high_risk_mcc_plus_high_value_elevates_radar_routes_review` — _High-risk MCC + high cart value passes silently, chargeback follows_
- [ ] `test_repeat_refund_abuse_3_in_30d_flags_buyer` — _Repeat-refund-abuse buyer reuses Gumroad freely, support manually flagging each time_
- [ ] `test_pump_and_dump_pattern_suspends_seller_holds_payout` — _Pump-and-dump seller paid out before scheme detected_
- [ ] `test_brand_impersonation_pattern_flags_compliance_review` — _Brand impersonation product never flagged, brand owner complaint hits CEO inbox_
- [ ] `test_stolen_card_success_credits_held_dispute_auto_conceded` — _Stolen-card test purchase credited to seller, dispute hits seller balance_
- [ ] `test_low_balance_fraud_check_holds_payout_pending_review` — _Risky seller paid out, then refunds bounce back as negative balance loss_

### `test/system/checkout/edge_cases/sca_test.rb` (0 / 8)

- [ ] `test_3ds_required_user_completes_challenge_succeeds` — _3DS challenge surfaces but completion isn't acked, no purchase row_
- [ ] `test_3ds_required_user_abandons_no_charge_no_purchase_row` — _User abandons 3DS but charge still goes through_
- [ ] `test_india_rbi_mandate_stored_on_first_charge` — _Indian buyer mandate not stored, recurring 2nd charge declines_
- [ ] `test_india_rbi_recurring_decline_flips_subscription_to_failed` — _2nd recurring charge fails silently, subscription stays active_
- [ ] `test_off_session_renewal_triggers_sca_buyer_emailed` — _Off-session renewal triggers SCA but buyer never notified_
- [ ] `test_saved_card_returning_customer_sca_challenge` — _Returning customer with saved card hits SCA but UX assumes frictionless_
- [ ] `test_low_value_eu_transaction_under_30_eur_exempt_from_3ds` — _Low-value EU transactions hitting 3DS unnecessarily, hurting conversion_
- [ ] `test_soft_decline_falls_back_to_frictionless_retry` — _Soft decline + 3DS path goes into infinite retry loop_

### `test/system/checkout/edge_cases/subscription_lifecycle_test.rb` (0 / 6)

- [ ] `test_first_charge_succeeds_second_declines_grace_period_then_cancel` — _2nd-charge decline silently cancels with no grace period_
- [ ] `test_paused_mid_cycle_no_charge_access_retained` — _Paused subscription still charged at next interval_
- [ ] `test_mid_cycle_upgrade_charged_prorated_in_buyer_currency` — _Mid-cycle upgrade charged in seller currency, ignoring buyer-local lock_
- [ ] `test_installment_plan_payment_2_of_4_fails_no_further_charges` — _Failed installment payment doesn't stop subsequent installments_
- [ ] `test_cancel_at_period_end_access_retained_until_then` — _End-of-period cancel revokes access before period ends_
- [ ] `test_stripe_customer_migrated_subscription_survives_no_double_bill` — _Stripe customer migration double-charges or strands subscription_

### `test/system/checkout/edge_cases/tax_quirks_test.rb` (0 / 8)

- [ ] `test_eu_b2b_buyer_with_valid_vatin_no_vat_charged` — _B2B buyer charged VAT despite valid VATIN_
- [ ] `test_eu_b2b_buyer_with_invalid_vatin_charges_vat_logs_error` — _Invalid VATIN treated as valid, under-collecting VAT_
- [ ] `test_us_sales_tax_ca_origin_based_vs_ny_destination_based` — _US sales tax origin/destination rules inverted by state_
- [ ] `test_eu_b2b_reverse_charge_line_on_invoice` — _B2B invoice missing reverse-charge line, accounting audit fail_
- [ ] `test_eu_digital_goods_oss_applied` — _Digital goods to EU under OSS not applied_
- [ ] `test_us_economic_nexus_tx_crossed_starts_collecting` — _Seller crosses TX $100K economic nexus but never starts collecting_
- [ ] `test_special_jurisdiction_mapping_pr_treated_as_us_territory` — _Puerto Rico / Northern Cyprus / etc. mapped to wrong jurisdiction_
- [ ] `test_locale_aware_inclusive_vs_exclusive_pricing_display` — _DE buyer shown tax-exclusive price, sticker-shocked at checkout_


## Product types  (0 / 34)

### `test/system/product/call_booking_test.rb` (0 / 4)

- [ ] `test_call_booking_requires_slot_selection` — _Slot skipped; double-booked_
- [ ] `test_call_slot_locks_to_buyer_after_purchase` — _Slot still bookable post-purchase; double-sold_
- [ ] `test_call_no_show_refund_policy_applied` — _Refund issued for no-show against seller policy_
- [ ] `test_call_reschedule_within_window_allowed` — _Reschedule blocked when window allows_

### `test/system/product/coffee_tip_test.rb` (0 / 5)

- [ ] `test_coffee_amount_above_minimum_accepted` — _Minimum bypassed; under-monetized_
- [ ] `test_coffee_amount_below_minimum_rejected` — _Minimum not enforced; abuse vector_
- [ ] `test_tip_added_to_main_purchase` — _Tip charged separately, breaks receipt math_
- [ ] `test_tip_charged_in_buyer_currency` — _Tip currency mismatch with main; FX drift_
- [ ] `test_zero_tip_skips_tip_line` — _$0 tip creates blank tip row; reports show ghost line items_

### `test/system/product/membership_test.rb` (0 / 8)

- [ ] `test_free_trial_converts_to_paid_at_window_end` — _Trial never converts; revenue lost_
- [ ] `test_plan_upgrade_prorates_correctly` — _Upgrade overcharges or undercharges; finance manual fix_
- [ ] `test_plan_downgrade_takes_effect_at_period_end` — _Downgrade refunds incorrectly mid-period_
- [ ] `test_cancel_at_period_end_retains_access_until_then` — _Cancellation revokes immediately; buyer rage_
- [ ] `test_subscription_payment_option_changes_billing_frequency` — _Frequency change skips a charge or double-charges_
- [ ] `test_subscription_purchase_with_existing_subscription_replaces_or_blocks` — _Duplicate subscription created; double-bill_
- [ ] `test_subscription_restart_after_cancel_creates_new_subscription` — _Restart resumes old sub; billing date stale_
- [ ] `test_subscription_with_installment_plan_charges_installments` — _Installment plan misfires on subscription_

### `test/system/product/physical_product_test.rb` (0 / 8)

- [ ] `test_physical_product_requires_shipping_address` — _Buyer checks out without address; seller can't fulfill_
- [ ] `test_shipping_cost_added_to_total` — _Shipping cost forgotten; seller eats shipping_
- [ ] `test_shipping_address_verification_blocks_invalid` — _Invalid address accepted; shipment lost_
- [ ] `test_shipping_to_virtual_country_handles_gracefully` — _Virtual country (Vatican etc.) crashes shipping calc_
- [ ] `test_shipping_offer_code_discounts_shipping_separately` — _Shipping discount applied to product instead_
- [ ] `test_physical_subscription_recurring_shipping` — _Recurring shipping not charged on renewal_
- [ ] `test_physical_preorder_charged_at_release` — _Preorder charged immediately, buyer chargebacks_
- [ ] `test_physical_quantity_oversell_prevention` — _Inventory race allows oversell_

### `test/system/product/preorder_test.rb` (0 / 5)

- [ ] `test_preorder_purchase_authorizes_card_does_not_charge` — _Charged at preorder time; buyer chargebacks for non-delivery_
- [ ] `test_preorder_charged_on_release_date` — _Charge never triggered at release; revenue lost_
- [ ] `test_preorder_release_date_change_notifies_buyer` — _Date change silent; buyer disputes_
- [ ] `test_preorder_cancelled_by_seller_voids_authorization` — _Cancellation leaves authorization hanging; buyer's card credit limit consumed_
- [ ] `test_preorder_card_declined_at_release_notifies_buyer` — _Decline silent; buyer never knows they didn't get product_

### `test/system/product/rental_test.rb` (0 / 4)

- [ ] `test_rental_purchase_grants_access_for_window` — _Access window calculated wrong; rental ends early_
- [ ] `test_rental_expires_revokes_access` — _Expired rental still has access; revenue cannibalized_
- [ ] `test_rental_purchase_displays_correct_window_on_receipt` — _Window text wrong on receipt, support burst_
- [ ] `test_rental_can_be_extended_with_new_purchase` — _Extension creates duplicate window; access doubled_


## Affiliate & collaborator  (0 / 10)

### `test/system/affiliate/affiliate_test.rb` (0 / 6)

- [ ] `test_affiliate_link_attributes_sale_to_affiliate` — _Affiliate link drops attribution; affiliate unpaid_
- [ ] `test_affiliate_commission_split_at_charge_time` — _Commission calc wrong; over/under-pays affiliate_
- [ ] `test_affiliate_self_purchase_blocked_or_no_commission` — _Affiliate buys own link; commission paid (fraud)_
- [ ] `test_affiliate_payout_held_until_refund_window_passes` — _Affiliate paid before refund window; clawback_
- [ ] `test_affiliate_link_with_offer_code_combines_correctly` — _Code+link combo over-discounts_
- [ ] `test_affiliate_signup_form_creates_account` — _Affiliate signup broken; partner can't join_

### `test/system/affiliate/collaborator_test.rb` (0 / 4)

- [ ] `test_collaborator_invited_accepts_share_set` — _Collaborator share invisible; payout missed_
- [ ] `test_collaborator_share_applied_at_payout_time` — _Share split wrong at payout; finance manual fix_
- [ ] `test_collaborator_removed_stops_future_shares` — _Removed collaborator still shares; double-payout_
- [ ] `test_pending_collaborator_does_not_receive_share` — _Pending collaborator receives share before accepting_


## Buyer account & library  (0 / 10)

### `test/system/buyer/account_test.rb` (0 / 5)

- [ ] `test_signup_after_purchase_links_account_to_purchase` — _Account not linked; library empty_
- [ ] `test_buyer_email_change_keeps_purchases` — _Purchases stranded on old email_
- [ ] `test_buyer_account_merge_transfers_purchases` — _Merge loses purchases on one side_
- [ ] `test_gdpr_export_returns_all_buyer_data` — _GDPR request returns partial data; compliance gap_
- [ ] `test_gdpr_delete_with_active_disputes_retains_purchase_rows` — _GDPR delete kills dispute evidence prematurely_

### `test/system/buyer/library_test.rb` (0 / 5)

- [ ] `test_library_shows_all_purchases` — _Purchases missing from library; support burst_
- [ ] `test_download_count_decrements_on_each_download` — _Download count not decremented; abuse_
- [ ] `test_revoked_purchase_hidden_from_library` — _Refunded purchase still downloadable; revenue cannibalized_
- [ ] `test_library_supports_pagination_for_heavy_buyers` — _Long library crashes; UX broken_
- [ ] `test_library_search_finds_by_creator_or_product` — _Search broken; buyer can't find old purchases_


## Seller flows  (0 / 29)

### `test/system/seller/analytics_test.rb` (0 / 5)

- [ ] `test_sales_chart_renders_correct_totals` — _Chart rendering shows wrong total; seller doubts data_
- [ ] `test_audience_chart_filters_by_country` — _Country filter broken; analytics misleading_
- [ ] `test_churn_chart_calculates_churn_rate` — _Churn formula wrong; bad decisions made_
- [ ] `test_utm_link_attribution_tracks_correct_source` — _UTM dropped; attribution lost_
- [ ] `test_date_range_persists_across_navigation` — _Date range reset on navigation; UX broken_

### `test/system/seller/dashboard_test.rb` (0 / 5)

- [ ] `test_dashboard_shows_recent_sales` — _Sales feed broken; seller blind to activity_
- [ ] `test_dashboard_shows_balance_and_next_payout_date` — _Balance display lags; seller doesn't know_
- [ ] `test_dashboard_links_to_payouts_page` — _Link broken; seller can't reach payout page_
- [ ] `test_dashboard_filters_by_date_range` — _Date filter broken; analytics wrong_
- [ ] `test_dashboard_mobile_layout_works` — _Mobile dashboard broken; seller can't manage on phone_

### `test/system/seller/onboarding_test.rb` (0 / 5)

- [ ] `test_seller_signup_creates_account_routes_to_setup` — _Signup routes wrong; seller confused_
- [ ] `test_stripe_connect_oauth_redirects_back_with_account_id` — _OAuth callback breaks; seller can't onboard_
- [ ] `test_stripe_connect_country_appropriate_account_type` — _Connect Express vs Standard chosen wrong; payouts fail later_
- [ ] `test_first_product_creation_displays_correctly` — _First product save crashes; seller abandons_
- [ ] `test_compliance_info_collected_before_first_payout` — _Payout attempted without KYC; Stripe blocks_

### `test/system/seller/payout_settings_test.rb` (0 / 4)

- [ ] `test_seller_changes_payout_schedule_takes_effect_next_cycle` — _Schedule change ignored; payout timing wrong_
- [ ] `test_seller_changes_bank_account_validates_routing_number` — _Invalid routing accepted; payout bounces_
- [ ] `test_seller_country_switch_requires_new_connect_account` — _Country switch silently corrupts existing balance_
- [ ] `test_seller_payout_currency_locks_at_account_creation` — _Payout currency changes mid-life; finance scramble_

### `test/system/seller/product_management_test.rb` (0 / 6)

- [ ] `test_product_create_with_minimum_fields_succeeds` — _Create flow broken; seller can't publish_
- [ ] `test_product_edit_preserves_existing_purchases` — _Edit invalidates URLs; buyers locked out_
- [ ] `test_product_archive_hides_from_discovery_keeps_library_access` — _Archive cuts library access; buyers locked out_
- [ ] `test_product_publish_makes_purchasable` — _Publish does nothing; seller waiting_
- [ ] `test_variant_add_works_with_existing_purchases` — _New variant breaks old purchases; rollback needed_
- [ ] `test_custom_domain_links_to_product` — _Custom domain breaks; product 404s_

### `test/system/seller/tax_settings_test.rb` (0 / 4)

- [ ] `test_vat_collection_toggle_starts_collecting_on_eu_sales` — _VAT toggle ignored; under-collecting_
- [ ] `test_us_sales_tax_state_selection_starts_collecting` — _State toggle ignored; nexus violated_
- [ ] `test_eu_oss_registration_routes_eu_vat_to_oss_filing` — _EU OSS not applied; double-reporting_
- [ ] `test_tax_inclusive_pricing_toggle_changes_display` — _Toggle ignored on product cards_


## API & webhooks  (0 / 22)

### `test/system/api/auth_test.rb` (0 / 5)

- [ ] `test_api_v2_request_with_valid_bearer_succeeds` — _Auth broken; entire API down_
- [ ] `test_api_v2_request_with_invalid_bearer_returns_401` — _Invalid token accepted; auth bypass_
- [ ] `test_api_v2_request_without_scope_returns_403` — _Scope ignored; abuse vector_
- [ ] `test_api_v2_rate_limit_returns_429_after_threshold` — _Rate limit ignored; API DOSed_
- [ ] `test_api_v2_expired_oauth_token_returns_401` — _Expired token accepted; security gap_

### `test/system/api/endpoints_test.rb` (0 / 6)

- [ ] `test_api_v2_purchases_returns_paginated_list` — _Pagination broken; integrations break_
- [ ] `test_api_v2_products_filters_by_visible_flag` — _Visibility filter broken; archived products leak_
- [ ] `test_api_v2_subscribers_search_by_email` — _Search broken; integrations break_
- [ ] `test_api_v2_sales_csv_export_returns_correct_columns` — _Column shift breaks downstream consumers_
- [ ] `test_api_v2_create_offer_code_returns_201` — _Create endpoint silently fails_
- [ ] `test_api_v2_files_multipart_upload_succeeds` — _Multipart broken; can't upload large files_

### `test/system/api/oauth_test.rb` (0 / 5)

- [ ] `test_oauth_app_register_creates_client_id_secret` — _Registration broken; partner integrations blocked_
- [ ] `test_oauth_authorize_redirect_includes_code` — _Code missing; auth flow broken_
- [ ] `test_oauth_token_exchange_returns_access_token` — _Exchange broken; partner can't connect_
- [ ] `test_oauth_token_refresh_extends_session` — _Refresh broken; partner re-auth churn_
- [ ] `test_oauth_revoke_invalidates_token` — _Revoke does nothing; security gap_

### `test/system/api/webhooks_outbound_test.rb` (0 / 6)

- [ ] `test_sale_event_delivers_to_seller_webhook` — _Webhook silently fails; seller's CRM out of sync_
- [ ] `test_refund_event_delivers_signed_payload` — _Signature wrong; consumer rejects_
- [ ] `test_webhook_failure_retries_with_backoff` — _No retry on transient failure; data lost_
- [ ] `test_webhook_delivery_failure_alerts_seller` — _Failure silent; seller doesn't know_
- [ ] `test_subscription_event_delivers_correct_state_transition` — _State transition omitted; consumer confused_
- [ ] `test_zapier_event_format_matches_schema` — _Schema drift breaks Zapier integration_


## Communication (emails)  (0 / 14)

### `test/system/communication/receipt_email_test.rb` (0 / 6)

- [ ] `test_receipt_email_sent_after_purchase` — _Receipt never sent; buyer thinks purchase failed_
- [ ] `test_receipt_email_contains_purchase_total_in_buyer_currency` — _Receipt shows wrong currency; confusion_
- [ ] `test_receipt_email_includes_download_links` — _Links missing; buyer can't access purchase_
- [ ] `test_multi_item_receipt_lists_all_items_with_correct_totals` — _Multi-item receipt math wrong_
- [ ] `test_invoice_attached_when_seller_invoice_enabled` — _Invoice not attached; B2B compliance gap_
- [ ] `test_receipt_email_localized_when_buyer_locale_set` — _Locale ignored; English email to FR buyer_

### `test/system/communication/seller_notification_test.rb` (0 / 4)

- [ ] `test_new_sale_email_delivered_to_seller` — _Sale notification missing; seller blind to activity_
- [ ] `test_dispute_created_email_with_response_deadline` — _Dispute email missed; default loss_
- [ ] `test_efw_email_with_recommended_action` — _EFW email missing; chargeback follows_
- [ ] `test_payout_sent_email_with_amount_and_destination` — _Payout email missing; seller can't reconcile_

### `test/system/communication/subscription_email_test.rb` (0 / 4)

- [ ] `test_renewal_reminder_sent_before_recurring_charge` — _Reminder missing; SCA exemption window missed_
- [ ] `test_payment_failed_email_with_update_card_link` — _No payment-failed email; subscription quietly cancels_
- [ ] `test_subscription_cancelled_email_confirms_end_date` — _Cancel email missing; buyer chargebacks_
- [ ] `test_subscription_paused_email_explains_resume` — _Paused email missing; buyer confused_


## Admin tools  (0 / 8)

### `test/system/admin/product_moderation_test.rb` (0 / 3)

- [ ] `test_admin_flag_product_hides_from_discovery` — _Flagged product still discoverable_
- [ ] `test_admin_takedown_product_revokes_buyer_access` — _Takedown leaves buyers with access to fraud product_
- [ ] `test_admin_mass_refund_for_fraud_product_processes_all_purchases` — _Mass refund partial; some buyers stranded_

### `test/system/admin/user_management_test.rb` (0 / 5)

- [ ] `test_admin_search_user_by_email_finds_match` — _Search broken; support paralyzed_
- [ ] `test_admin_suspend_user_blocks_login_and_payouts` — _Suspend leaves loopholes_
- [ ] `test_admin_reinstate_user_restores_access` — _Reinstate doesn't restore payouts_
- [ ] `test_admin_impersonate_user_logs_audit_trail` — _Impersonation untracked; abuse vector_
- [ ] `test_admin_view_unreviewed_users_filters_correctly` — _Risk queue broken; reviews backlog_


## Concurrency & race conditions  (0 / 5)

### `test/system/concurrency/race_condition_test.rb` (0 / 5)

- [ ] `test_concurrent_purchase_same_limited_inventory_does_not_oversell` — _Oversell creates fulfillment crisis_
- [ ] `test_concurrent_refund_requests_same_purchase_idempotent` — _Double-refund issued; clawback needed_
- [ ] `test_concurrent_webhook_deliveries_for_same_event_idempotent` — _Double-processed webhook = double state change_
- [ ] `test_simultaneous_subscription_renewal_and_cancellation_no_charge` — _Cancel race lost; buyer charged after cancel_
- [ ] `test_simultaneous_payout_and_refund_balance_consistent` — _Payout + refund race leaves balance corrupted_


## Discovery & search  (0 / 5)

### `test/system/discovery/search_test.rb` (0 / 5)

- [ ] `test_discover_search_returns_relevant_products` — _Search broken; discovery dead_
- [ ] `test_discover_category_filter_narrows_results` — _Filter broken; discovery noise_
- [ ] `test_public_profile_lists_seller_products` — _Profile broken; seller can't share link_
- [ ] `test_recommendations_show_related_products` — _Recommendations dead; conversion lost_
- [ ] `test_wishlist_add_persists_for_logged_in_buyer` — _Wishlist lost; buyer leaves_


## Embed (overlay/iframe)  (0 / 4)

### `test/system/embed/embed_test.rb` (0 / 4)

- [ ] `test_embed_overlay_loads_product_button` — _Embed broken; seller's external site purchases dead_
- [ ] `test_embed_overlay_opens_purchase_modal` — _Modal won't open; conversion lost_
- [ ] `test_embed_iframe_purchases_attribute_to_correct_seller` — _Attribution lost; revenue going to wrong account_
- [ ] `test_embed_with_offer_code_query_param_applies_discount` — _Code in URL ignored; promo broken_


## Security & abuse  (0 / 5)

### `test/system/security/abuse_prevention_test.rb` (0 / 5)

- [ ] `test_rack_attack_blocks_after_burst_of_failed_logins` — _Brute force unprotected; account takeover_
- [ ] `test_cors_headers_present_on_public_api` — _CORS missing; integrations break_
- [ ] `test_cors_headers_absent_on_authenticated_routes` — _CORS too permissive; CSRF risk_
- [ ] `test_dangerous_inputs_caught_and_sanitized` — _XSS in product description executes for buyers_
- [ ] `test_session_fixation_prevented_on_login` — _Session fixation; account hijack_
