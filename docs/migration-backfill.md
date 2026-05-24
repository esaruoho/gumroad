# Skip-Stub Backfill Inventory
Tracks the ~649 silenced test methods across ~643 files left after the bulk RSpec→Minitest migration (#5244).
**Issue:** [#5257](https://github.com/antiwork/gumroad/issues/5257)  
**Generated from:** `rg -c '^\s*skip\b' test/`  
**Definition of done:** `rg -c '^\s*skip\b' test/` returns 0.

## Status legend
- ⬜ untouched skip-stub
- 🟨 in-progress (PR open)
- ✅ backfilled (real assertions, no skip) or deleted with justification

## Summary

| Domain | Files | Skips |
|---|---:|---:|
| `test/controllers/` | 222 | 222 |
| `test/models/` | 104 | 104 |
| `test/services/` | 99 | 99 |
| `test/sidekiq/` | 77 | 77 |
| `test/presenters/` | 62 | 67 |
| `test/modules/` | 32 | 32 |
| `test/business/` | 25 | 25 |
| `test/mailers/` | 0 | 0 |
| `test/lib/` | 4 | 4 |
| `test/observers/` | 0 | 0 |
| `test/helpers/` | 2 | 2 |
| `test/policies/` | 1 | 1 |
| `test/jobs/` | 1 | 1 |
| `test/root/` | 1 | 1 |
| **Total** | **639** | **645** |

## Suggested batch order
Models first (core behavior), then services/sidekiq (business logic), then controllers/presenters (thinner orchestration), then leaves (mailers/helpers/policies).

1. `test/models/` — heaviest model-behavior coverage gap
2. `test/services/`
3. `test/sidekiq/`
4. `test/business/`
5. `test/controllers/`
6. `test/presenters/`
7. `test/modules/`, `test/lib/`, `test/mailers/`, `test/helpers/`, `test/policies/`, `test/observers/`, `test/jobs/`

## `test/controllers/` (222 files, 222 skips)

| Status | File | Skips |
|---|---|---:|
| ⬜ | `test/controllers/workflows_controller_test.rb` | 1 |
| ⬜ | `test/controllers/workflows/emails_controller_test.rb` | 1 |
| ⬜ | `test/controllers/wishlists_controller_test.rb` | 1 |
| ⬜ | `test/controllers/wishlists/products_controller_test.rb` | 1 |
| ⬜ | `test/controllers/wishlists/following_controller_test.rb` | 1 |
| ⬜ | `test/controllers/wishlists/followers_controller_test.rb` | 1 |
| ⬜ | `test/controllers/utm_links_controller_test.rb` | 1 |
| ⬜ | `test/controllers/users_controller_test.rb` | 1 |
| ⬜ | `test/controllers/users/review_reminders_controller_test.rb` | 1 |
| ⬜ | `test/controllers/user/passwords_controller_test.rb` | 1 |
| ⬜ | `test/controllers/user/omniauth_callbacks_controller_test.rb` | 1 |
| ⬜ | `test/controllers/user/invalidate_active_sessions_controller_test.rb` | 1 |
| ⬜ | `test/controllers/url_redirects_controller_test.rb` | 1 |
| ⬜ | `test/controllers/two_factor_authentication_controller_test.rb` | 1 |
| ⬜ | `test/controllers/thumbnails_controller_test.rb` | 1 |
| ⬜ | `test/controllers/third_party_analytics_controller_test.rb` | 1 |
| ⬜ | `test/controllers/test_pings_controller_test.rb` | 1 |
| ⬜ | `test/controllers/tax_center_controller_test.rb` | 1 |
| ⬜ | `test/controllers/subscriptions_controller_test.rb` | 1 |
| ⬜ | `test/controllers/subscriptions/magic_links_controller_test.rb` | 1 |
| ⬜ | `test/controllers/stripe/setup_intents_controller_test.rb` | 1 |
| ⬜ | `test/controllers/signup_controller_test.rb` | 1 |
| ⬜ | `test/controllers/shipments_controller_test.rb` | 1 |
| ⬜ | `test/controllers/settings/totp_controller_test.rb` | 1 |
| ⬜ | `test/controllers/settings/third_party_analytics_controller_test.rb` | 1 |
| ⬜ | `test/controllers/settings/team_controller_test.rb` | 1 |
| ⬜ | `test/controllers/settings/team/members_controller_test.rb` | 1 |
| ⬜ | `test/controllers/settings/team/invitations_controller_test.rb` | 1 |
| ⬜ | `test/controllers/settings/stripe_controller_test.rb` | 1 |
| ⬜ | `test/controllers/settings/profile_controller_test.rb` | 1 |
| ⬜ | `test/controllers/settings/profile/products_controller_test.rb` | 1 |
| ⬜ | `test/controllers/settings/payments_controller_test.rb` | 1 |
| ⬜ | `test/controllers/settings/password_controller_test.rb` | 1 |
| ⬜ | `test/controllers/settings/main_controller_test.rb` | 1 |
| ⬜ | `test/controllers/settings/dismiss_ai_product_generation_promos_controller_test.rb` | 1 |
| ⬜ | `test/controllers/settings/billing_controller_test.rb` | 1 |
| ⬜ | `test/controllers/settings/beneficial_owners_controller_test.rb` | 1 |
| ⬜ | `test/controllers/settings/authorized_applications_controller_test.rb` | 1 |
| ⬜ | `test/controllers/settings/advanced_controller_test.rb` | 1 |
| ⬜ | `test/controllers/sellers/switch_controller_test.rb` | 1 |
| ⬜ | `test/controllers/sellers/base_controller_test.rb` | 1 |
| ⬜ | `test/controllers/s3_utility_controller_test.rb` | 1 |
| ⬜ | `test/controllers/reviews_controller_test.rb` | 1 |
| ⬜ | `test/controllers/recommended_products_controller_test.rb` | 1 |
| ⬜ | `test/controllers/purchases_controller_test.rb` | 1 |
| ⬜ | `test/controllers/purchases/variants_controller_test.rb` | 1 |
| ⬜ | `test/controllers/purchases/product_controller_test.rb` | 1 |
| ⬜ | `test/controllers/purchases/pings_controller_test.rb` | 1 |
| ⬜ | `test/controllers/purchases/invoices_controller_test.rb` | 1 |
| ⬜ | `test/controllers/purchases/dispute_evidence_controller_test.rb` | 1 |
| ⬜ | `test/controllers/purchase_custom_fields_controller_test.rb` | 1 |
| ⬜ | `test/controllers/public_controller_test.rb` | 1 |
| ⬜ | `test/controllers/profile_sections_controller_test.rb` | 1 |
| ⬜ | `test/controllers/products/variants_controller_test.rb` | 1 |
| ⬜ | `test/controllers/products/remaining_call_availabilities_controller_test.rb` | 1 |
| ⬜ | `test/controllers/products/product_files_utility_controller_test.rb` | 1 |
| ⬜ | `test/controllers/products/other_refund_policies_controller_test.rb` | 1 |
| ⬜ | `test/controllers/products/collabs_controller_test.rb` | 1 |
| ⬜ | `test/controllers/products/available_offer_codes_controller_test.rb` | 1 |
| ⬜ | `test/controllers/products/archived_controller_test.rb` | 1 |
| ⬜ | `test/controllers/products/affiliated_controller_test.rb` | 1 |
| ⬜ | `test/controllers/product_reviews_controller_test.rb` | 1 |
| ⬜ | `test/controllers/product_review_videos/streams_controller_test.rb` | 1 |
| ⬜ | `test/controllers/product_review_videos/streaming_urls_controller_test.rb` | 1 |
| ⬜ | `test/controllers/product_review_responses_controller_test.rb` | 1 |
| ⬜ | `test/controllers/product_duplicates_controller_test.rb` | 1 |
| ⬜ | `test/controllers/posts_controller_test.rb` | 1 |
| ⬜ | `test/controllers/paypal_controller_test.rb` | 1 |
| ⬜ | `test/controllers/payouts/exports_controller_test.rb` | 1 |
| ⬜ | `test/controllers/payouts/exportables_controller_test.rb` | 1 |
| ⬜ | `test/controllers/orders_controller_test.rb` | 1 |
| ⬜ | `test/controllers/offer_codes_controller_test.rb` | 1 |
| ⬜ | `test/controllers/oauth_completions_controller_test.rb` | 1 |
| ⬜ | `test/controllers/oauth/mobile_pre_authorizations_controller_test.rb` | 1 |
| ⬜ | `test/controllers/oauth/authorized_applications_controller_test.rb` | 1 |
| ⬜ | `test/controllers/oauth/authorizations_controller_test.rb` | 1 |
| ⬜ | `test/controllers/oauth/applications_controller_test.rb` | 1 |
| ⬜ | `test/controllers/oauth/access_tokens_constroller_test.rb` | 1 |
| ⬜ | `test/controllers/media_locations_controller_test.rb` | 1 |
| ⬜ | `test/controllers/logins_controller_test.rb` | 1 |
| ⬜ | `test/controllers/links_controller_test.rb` | 1 |
| ⬜ | `test/controllers/licenses_controller_test.rb` | 1 |
| ⬜ | `test/controllers/library_controller_test.rb` | 1 |
| ⬜ | `test/controllers/integrations/zoom_controller_test.rb` | 1 |
| ⬜ | `test/controllers/integrations/google_calendar_controller_test.rb` | 1 |
| ⬜ | `test/controllers/integrations/discord_controller_test.rb` | 1 |
| ⬜ | `test/controllers/integrations/circle_controller_test.rb` | 1 |
| ⬜ | `test/controllers/instant_payouts_controller_test.rb` | 1 |
| ⬜ | `test/controllers/imported_customers_controller_test.rb` | 1 |
| ⬜ | `test/controllers/healthcheck_controller_test.rb` | 1 |
| ⬜ | `test/controllers/gumroad_blog/posts_controller_test.rb` | 1 |
| ⬜ | `test/controllers/global_affiliates/product_eligibility_controller_test.rb` | 1 |
| ⬜ | `test/controllers/foreign_webhooks_controller_test.rb` | 1 |
| ⬜ | `test/controllers/followers_controller_test.rb` | 1 |
| ⬜ | `test/controllers/emails_controller_test.rb` | 1 |
| ⬜ | `test/controllers/dropbox_files_controller_test.rb` | 1 |
| ⬜ | `test/controllers/discover_controller_test.rb` | 1 |
| ⬜ | `test/controllers/discover/search_autocomplete_controller_test.rb` | 1 |
| ⬜ | `test/controllers/dashboard_controller_test.rb` | 1 |
| ⬜ | `test/controllers/customers_controller_test.rb` | 1 |
| ⬜ | `test/controllers/customer_surcharge_controller_test.rb` | 1 |
| ⬜ | `test/controllers/custom_domain/verifications_controller_test.rb` | 1 |
| ⬜ | `test/controllers/consumption_analytics_controller_test.rb` | 1 |
| ⬜ | `test/controllers/connections_controller_test.rb` | 1 |
| ⬜ | `test/controllers/concerns/utm_link_tracking_test.rb` | 1 |
| ⬜ | `test/controllers/concerns/two_factor_authentication_validator_test.rb` | 1 |
| ⬜ | `test/controllers/concerns/pundit_authorization_test.rb` | 1 |
| ⬜ | `test/controllers/concerns/impersonate_test.rb` | 1 |
| ⬜ | `test/controllers/concerns/custom_domain_route_builder_test.rb` | 1 |
| ⬜ | `test/controllers/concerns/current_seller_test.rb` | 1 |
| ⬜ | `test/controllers/concerns/current_api_user_test.rb` | 1 |
| ⬜ | `test/controllers/communities_controller_test.rb` | 1 |
| ⬜ | `test/controllers/communities/notification_settings_controller_test.rb` | 1 |
| ⬜ | `test/controllers/communities/last_read_chat_messages_controller_test.rb` | 1 |
| ⬜ | `test/controllers/communities/chat_messages_controller_test.rb` | 1 |
| ⬜ | `test/controllers/commissions_controller_test.rb` | 1 |
| ⬜ | `test/controllers/comments_controller_test.rb` | 1 |
| ⬜ | `test/controllers/collaborators/main_controller_test.rb` | 1 |
| ⬜ | `test/controllers/collaborators/incomings_controller_test.rb` | 1 |
| ⬜ | `test/controllers/churn_controller_test.rb` | 1 |
| ⬜ | `test/controllers/checkout_controller_test.rb` | 1 |
| ⬜ | `test/controllers/checkout/upsells_controller_test.rb` | 1 |
| ⬜ | `test/controllers/checkout/upsells/products_controller_test.rb` | 1 |
| ⬜ | `test/controllers/checkout/upsells/pauses_controller_test.rb` | 1 |
| ⬜ | `test/controllers/checkout/form_controller_test.rb` | 1 |
| ⬜ | `test/controllers/checkout/discounts_controller_test.rb` | 1 |
| ⬜ | `test/controllers/calls_controller_test.rb` | 1 |
| ⬜ | `test/controllers/bundles_controller_test.rb` | 1 |
| ⬜ | `test/controllers/bundles/share_controller_test.rb` | 1 |
| ⬜ | `test/controllers/bundles/product_controller_test.rb` | 1 |
| ⬜ | `test/controllers/bundles/content_controller_test.rb` | 1 |
| ⬜ | `test/controllers/braintree_controller_test.rb` | 1 |
| ⬜ | `test/controllers/balance_controller_test.rb` | 1 |
| ⬜ | `test/controllers/audience_controller_test.rb` | 1 |
| ⬜ | `test/controllers/asset_previews_controller_test.rb` | 1 |
| ⬜ | `test/controllers/application_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/v2/variants_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/v2/variant_categories_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/v2/users_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/v2/thumbnails_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/v2/tax_forms_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/v2/subscribers_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/v2/skus_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/v2/sales_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/v2/resource_subscriptions_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/v2/payouts_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/v2/offer_codes_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/v2/notion_unfurl_urls_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/v2/links_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/v2/licenses_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/v2/files_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/v2/earnings_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/v2/direct_uploads_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/v2/custom_fields_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/v2/covers_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/v2/bundle_contents_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/mobile/url_redirects_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/mobile/subscriptions_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/mobile/sessions_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/mobile/sales_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/mobile/purchases_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/mobile/media_locations_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/mobile/installments_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/mobile/feature_flags_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/mobile/devices_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/mobile/consumption_analytics_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/mobile/base_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/mobile/analytics_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/internal/product_review_videos/rejections_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/internal/product_review_videos/approvals_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/internal/product_public_files_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/internal/product_posts_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/internal/mobile_minimum_versions_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/internal/installments/recipient_counts_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/internal/installments/preview_emails_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/internal/installments/audience_counts_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/internal/helper/users_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/internal/helper/purchases_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/internal/helper/payouts_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/internal/helper/instant_payouts_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/internal/existing_product_files_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/internal/ai_product_details_generations_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/internal/admin/whoami_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/internal/admin/users_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/internal/admin/scheduled_payouts_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/internal/admin/purchases_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/internal/admin/products_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/internal/admin/payouts_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/internal/admin/base_controller_test.rb` | 1 |
| ⬜ | `test/controllers/api/internal/admin/auth_controller_test.rb` | 1 |
| ⬜ | `test/controllers/analytics_controller_test.rb` | 1 |
| ⬜ | `test/controllers/affiliates_controller_test.rb` | 1 |
| ⬜ | `test/controllers/affiliate_requests_controller_test.rb` | 1 |
| ⬜ | `test/controllers/affiliate_requests/onboarding_form_controller_test.rb` | 1 |
| ⬜ | `test/controllers/affiliate_redirect_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/users_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/users/watchlists_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/users/stats_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/users/products_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/users/products/tos_violation_flags_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/users/payouts_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/users/merchant_accounts_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/users/latest_posts_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/users/guids_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/users/email_changes_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/search/users_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/search/purchases_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/scheduled_payouts_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/purchases_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/products/staff_picked_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/products/purchases_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/payouts_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/paydays_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/merchant_accounts_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/links_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/helper_actions_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/compliance/cards_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/block_email_domains_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/base_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/affiliates_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/affiliates/products_controller_test.rb` | 1 |
| ⬜ | `test/controllers/admin/affiliates/products/purchases_controller_test.rb` | 1 |

## `test/models/` (104 files, 104 skips)

| Status | File | Skips |
|---|---|---:|
| ⬜ | `test/models/workflow_test.rb` | 1 |
| ⬜ | `test/models/wishlist_test.rb` | 1 |
| ⬜ | `test/models/wishlist_product_test.rb` | 1 |
| ⬜ | `test/models/variant_test.rb` | 1 |
| ⬜ | `test/models/variant_category_test.rb` | 1 |
| ⬜ | `test/models/utm_link_test.rb` | 1 |
| ⬜ | `test/models/user_test.rb` | 1 |
| ⬜ | `test/models/user_compliance_info_test.rb` | 1 |
| ⬜ | `test/models/user_compliance_info_request_test.rb` | 1 |
| ⬜ | `test/models/url_redirect_test.rb` | 1 |
| ⬜ | `test/models/upsell_test.rb` | 1 |
| ⬜ | `test/models/upsell_purchase_test.rb` | 1 |
| ⬜ | `test/models/thumbnail_test.rb` | 1 |
| ⬜ | `test/models/subscription_test.rb` | 1 |
| ⬜ | `test/models/shipping_destination_test.rb` | 1 |
| ⬜ | `test/models/service_charge_test.rb` | 1 |
| ⬜ | `test/models/scheduled_payout_test.rb` | 1 |
| ⬜ | `test/models/sales_related_products_info_test.rb` | 1 |
| ⬜ | `test/models/rich_content_test.rb` | 1 |
| ⬜ | `test/models/resend_event_info_test.rb` | 1 |
| ⬜ | `test/models/purchase_test.rb` | 1 |
| ⬜ | `test/models/purchase_custom_field_test.rb` | 1 |
| ⬜ | `test/models/purchase/purchase_zip_test.rb` | 1 |
| ⬜ | `test/models/purchase/purchase_taxation_test.rb` | 1 |
| ⬜ | `test/models/purchase/purchase_subscription_test.rb` | 1 |
| ⬜ | `test/models/purchase/purchase_sales_tax_test.rb` | 1 |
| ⬜ | `test/models/purchase/purchase_refunds_test.rb` | 1 |
| ⬜ | `test/models/purchase/purchase_process_test.rb` | 1 |
| ⬜ | `test/models/purchase/purchase_notification_test.rb` | 1 |
| ⬜ | `test/models/purchase/purchase_installments_test.rb` | 1 |
| ⬜ | `test/models/purchase/purchase_gifts_test.rb` | 1 |
| ⬜ | `test/models/purchase/purchase_balances_test.rb` | 1 |
| ⬜ | `test/models/purchase/inventory_counter_cache_test.rb` | 1 |
| ⬜ | `test/models/public_file_test.rb` | 1 |
| ⬜ | `test/models/product_review_test.rb` | 1 |
| ⬜ | `test/models/product_review_stat_test.rb` | 1 |
| ⬜ | `test/models/product_page_view_test.rb` | 1 |
| ⬜ | `test/models/product_installment_plan_test.rb` | 1 |
| ⬜ | `test/models/product_files_archive_test.rb` | 1 |
| ⬜ | `test/models/product_file_test.rb` | 1 |
| ⬜ | `test/models/product_cached_value_test.rb` | 1 |
| ⬜ | `test/models/product_affiliate_test.rb` | 1 |
| ⬜ | `test/models/preorder_test.rb` | 1 |
| ⬜ | `test/models/preorder_link_test.rb` | 1 |
| ⬜ | `test/models/post_email_blast_test.rb` | 1 |
| ⬜ | `test/models/payment_test.rb` | 1 |
| ⬜ | `test/models/payment_option/installment_plan_snapshot_test.rb` | 1 |
| ⬜ | `test/models/order_test.rb` | 1 |
| ⬜ | `test/models/offer_code_test.rb` | 1 |
| ⬜ | `test/models/oauth_application_test.rb` | 1 |
| ⬜ | `test/models/merchant_account_test.rb` | 1 |
| ⬜ | `test/models/link_test.rb` | 1 |
| ⬜ | `test/models/japan_bank_account_test.rb` | 1 |
| ⬜ | `test/models/installment_test.rb` | 1 |
| ⬜ | `test/models/installment_plan_snapshot_test.rb` | 1 |
| ⬜ | `test/models/installment/installment_validations_test.rb` | 1 |
| ⬜ | `test/models/installment/installment_send_installment_test.rb` | 1 |
| ⬜ | `test/models/installment/installment_json_test.rb` | 1 |
| ⬜ | `test/models/installment/installment_filters_test.rb` | 1 |
| ⬜ | `test/models/installment/installment_class_methods_test.rb` | 1 |
| ⬜ | `test/models/global_affiliate_test.rb` | 1 |
| ⬜ | `test/models/follower_test.rb` | 1 |
| ⬜ | `test/models/email_event_test.rb` | 1 |
| ⬜ | `test/models/early_fraud_warning_test.rb` | 1 |
| ⬜ | `test/models/dispute_evidence_test.rb` | 1 |
| ⬜ | `test/models/direct_affiliate_test.rb` | 1 |
| ⬜ | `test/models/custom_domain_test.rb` | 1 |
| ⬜ | `test/models/credit_test.rb` | 1 |
| ⬜ | `test/models/credit_card_test.rb` | 1 |
| ⬜ | `test/models/confirmed_follower_event_test.rb` | 1 |
| ⬜ | `test/models/concerns/with_filtering_test.rb` | 1 |
| ⬜ | `test/models/concerns/user/team_test.rb` | 1 |
| ⬜ | `test/models/concerns/user/taxation_test.rb` | 1 |
| ⬜ | `test/models/concerns/user/low_balance_fraud_check_test.rb` | 1 |
| ⬜ | `test/models/concerns/user/affiliated_products_test.rb` | 1 |
| ⬜ | `test/models/concerns/two_factor_authentication_test.rb` | 1 |
| ⬜ | `test/models/concerns/purchase/searchable_test.rb` | 1 |
| ⬜ | `test/models/concerns/purchase/receipt_test.rb` | 1 |
| ⬜ | `test/models/concerns/purchase/charge_events_handler_test.rb` | 1 |
| ⬜ | `test/models/concerns/purchase/blockable_test.rb` | 1 |
| ⬜ | `test/models/concerns/product/structured_data_test.rb` | 1 |
| ⬜ | `test/models/concerns/product/sorting_test.rb` | 1 |
| ⬜ | `test/models/concerns/product/as_json_test.rb` | 1 |
| ⬜ | `test/models/concerns/order/orderable_test.rb` | 1 |
| ⬜ | `test/models/concerns/charge/disputable_test.rb` | 1 |
| ⬜ | `test/models/concerns/charge/chargeable_test.rb` | 1 |
| ⬜ | `test/models/concerns/balance/searchable_test.rb` | 1 |
| ⬜ | `test/models/concerns/attribute_blockable_test.rb` | 1 |
| ⬜ | `test/models/community_chat_recap_run_test.rb` | 1 |
| ⬜ | `test/models/commission_test.rb` | 1 |
| ⬜ | `test/models/comment_test.rb` | 1 |
| ⬜ | `test/models/collaborator_test.rb` | 1 |
| ⬜ | `test/models/charge_test.rb` | 1 |
| ⬜ | `test/models/cart_test.rb` | 1 |
| ⬜ | `test/models/card_bank_account_test.rb` | 1 |
| ⬜ | `test/models/call_test.rb` | 1 |
| ⬜ | `test/models/call_limitation_info_test.rb` | 1 |
| ⬜ | `test/models/bundle_product_test.rb` | 1 |
| ⬜ | `test/models/balance_transaction_test.rb` | 1 |
| ⬜ | `test/models/audience_member_test.rb` | 1 |
| ⬜ | `test/models/asset_preview_test.rb` | 1 |
| ⬜ | `test/models/affiliate_test.rb` | 1 |
| ⬜ | `test/models/affiliate_request_test.rb` | 1 |
| ⬜ | `test/models/ach_account_test.rb` | 1 |

## `test/services/` (99 files, 99 skips)

| Status | File | Skips |
|---|---|---:|
| ⬜ | `test/services/workflow/save_installments_service_test.rb` | 1 |
| ⬜ | `test/services/workflow/manage_service_test.rb` | 1 |
| ⬜ | `test/services/username_generator_service_test.rb` | 1 |
| ⬜ | `test/services/user_balance_stats_service_test.rb` | 1 |
| ⬜ | `test/services/update_user_country_test.rb` | 1 |
| ⬜ | `test/services/update_payout_method_test.rb` | 1 |
| ⬜ | `test/services/subscription/updater_service_test.rb` | 1 |
| ⬜ | `test/services/subscription/updater_service/tiered_membership_variant_and_price_update_test.rb` | 1 |
| ⬜ | `test/services/subscription/restart_at_checkout_service_test.rb` | 1 |
| ⬜ | `test/services/subscribe_preview_generator_service_test.rb` | 1 |
| ⬜ | `test/services/ssl_certificates/generate_test.rb` | 1 |
| ⬜ | `test/services/ssl_certificates/base_test.rb` | 1 |
| ⬜ | `test/services/sitemap_service_test.rb` | 1 |
| ⬜ | `test/services/seller_mobile_analytics_service_test.rb` | 1 |
| ⬜ | `test/services/save_installment_service_test.rb` | 1 |
| ⬜ | `test/services/recommended_products/checkout_service_test.rb` | 1 |
| ⬜ | `test/services/push_notification_service/android_test.rb` | 1 |
| ⬜ | `test/services/purchase_search_service_test.rb` | 1 |
| ⬜ | `test/services/purchase/variant_updater_service_test.rb` | 1 |
| ⬜ | `test/services/purchase/update_bundle_purchase_content_service_test.rb` | 1 |
| ⬜ | `test/services/purchase/sync_status_with_charge_processor_service_test.rb` | 1 |
| ⬜ | `test/services/purchase/reassign_by_email_service_test.rb` | 1 |
| ⬜ | `test/services/purchase/mark_successful_service_test.rb` | 1 |
| ⬜ | `test/services/purchase/create_service_test.rb` | 1 |
| ⬜ | `test/services/purchase/create_bundle_product_purchase_service_test.rb` | 1 |
| ⬜ | `test/services/purchase/confirm_service_test.rb` | 1 |
| ⬜ | `test/services/purchase/associate_bundle_product_level_gift_service_test.rb` | 1 |
| ⬜ | `test/services/product_duplicator_service_test.rb` | 1 |
| ⬜ | `test/services/product/variants_updater_service_test.rb` | 1 |
| ⬜ | `test/services/product/variant_category_updater_service_test.rb` | 1 |
| ⬜ | `test/services/product/save_post_purchase_custom_fields_service_test.rb` | 1 |
| ⬜ | `test/services/product/save_integrations_service_test.rb` | 1 |
| ⬜ | `test/services/product/save_cancellation_discount_service_test.rb` | 1 |
| ⬜ | `test/services/product/compute_call_availabilities_service_test.rb` | 1 |
| ⬜ | `test/services/product/bulk_update_support_email_service_test.rb` | 1 |
| ⬜ | `test/services/price_checker_service_test.rb` | 1 |
| ⬜ | `test/services/post_sendgrid_api_test.rb` | 1 |
| ⬜ | `test/services/post_resend_api_test.rb` | 1 |
| ⬜ | `test/services/pdf_stamping_service/stamp_test.rb` | 1 |
| ⬜ | `test/services/pdf_stamping_service/stamp_for_purchase_test.rb` | 1 |
| ⬜ | `test/services/payout_users_service_test.rb` | 1 |
| ⬜ | `test/services/order/response_helpers_test.rb` | 1 |
| ⬜ | `test/services/order/create_service_test.rb` | 1 |
| ⬜ | `test/services/order/confirm_service_test.rb` | 1 |
| ⬜ | `test/services/order/charge_service_test.rb` | 1 |
| ⬜ | `test/services/onetime/backfill_stripe_disabled_reason_test.rb` | 1 |
| ⬜ | `test/services/onetime/backfill_radar_value_lists_test.rb` | 1 |
| ⬜ | `test/services/onetime/backfill_price_checker_index_fields_test.rb` | 1 |
| ⬜ | `test/services/onetime/backfill_license_uses_for_seller_test.rb` | 1 |
| ⬜ | `test/services/onetime/backfill_inventory_counter_cache_test.rb` | 1 |
| ⬜ | `test/services/offer_code_discount_computing_service_test.rb` | 1 |
| ⬜ | `test/services/notion_api_test.rb` | 1 |
| ⬜ | `test/services/mailer_attachment_or_link_service_test.rb` | 1 |
| ⬜ | `test/services/integrations/discord_integration_service_test.rb` | 1 |
| ⬜ | `test/services/integrations/circle_integration_service_test.rb` | 1 |
| ⬜ | `test/services/instant_payouts_service_test.rb` | 1 |
| ⬜ | `test/services/installment_search_service_test.rb` | 1 |
| ⬜ | `test/services/helper_user_info_service_test.rb` | 1 |
| ⬜ | `test/services/helper/unblock_email_service_test.rb` | 1 |
| ⬜ | `test/services/handle_email_event_info/for_receipt_email_test.rb` | 1 |
| ⬜ | `test/services/handle_email_event_info/for_installment_email_test.rb` | 1 |
| ⬜ | `test/services/handle_email_event_info/for_abandoned_cart_email_test.rb` | 1 |
| ⬜ | `test/services/gdpr_data_erasure_service_test.rb` | 1 |
| ⬜ | `test/services/gdpr_buyer_erasure_service_test.rb` | 1 |
| ⬜ | `test/services/follower/create_service_test.rb` | 1 |
| ⬜ | `test/services/exports/tax_summary/annual_test.rb` | 1 |
| ⬜ | `test/services/exports/purchase_export_service_test.rb` | 1 |
| ⬜ | `test/services/exports/payouts/csv_test.rb` | 1 |
| ⬜ | `test/services/exports/audience_export_service_test.rb` | 1 |
| ⬜ | `test/services/exports/affiliate_export_service_test.rb` | 1 |
| ⬜ | `test/services/expiring_s3_file_service_test.rb` | 1 |
| ⬜ | `test/services/email_suppression_manager_test.rb` | 1 |
| ⬜ | `test/services/early_fraud_warning/update_service_test.rb` | 1 |
| ⬜ | `test/services/dispute_evidence/create_from_dispute_service_test.rb` | 1 |
| ⬜ | `test/services/creator_analytics/sales_test.rb` | 1 |
| ⬜ | `test/services/creator_analytics/product_page_views_test.rb` | 1 |
| ⬜ | `test/services/creator_analytics/churn_test.rb` | 1 |
| ⬜ | `test/services/creator_analytics/churn/product_scope_test.rb` | 1 |
| ⬜ | `test/services/creator_analytics/churn/elasticsearch_fetcher_test.rb` | 1 |
| ⬜ | `test/services/creator_analytics/churn/date_window_test.rb` | 1 |
| ⬜ | `test/services/creator_analytics/caching_proxy_test.rb` | 1 |
| ⬜ | `test/services/content_moderation/content_extractor_test.rb` | 1 |
| ⬜ | `test/services/community_chat_recap_generator_service_test.rb` | 1 |
| ⬜ | `test/services/collaborator/update_service_test.rb` | 1 |
| ⬜ | `test/services/collaborator/create_service_test.rb` | 1 |
| ⬜ | `test/services/circle_api_test.rb` | 1 |
| ⬜ | `test/services/charge/create_service_test.rb` | 1 |
| ⬜ | `test/services/bundle_search_products_service_test.rb` | 1 |
| ⬜ | `test/services/black_friday_stats_service_test.rb` | 1 |
| ⬜ | `test/services/best_offer_code_service_test.rb` | 1 |
| ⬜ | `test/services/balances_by_product_service_test.rb` | 1 |
| ⬜ | `test/services/api/v2/sales_summary_test.rb` | 1 |
| ⬜ | `test/services/admin_search_service_test.rb` | 1 |
| ⬜ | `test/services/admin_funds_csv_report_service_test.rb` | 1 |
| ⬜ | `test/services/admin/unreviewed_users_service_test.rb` | 1 |
| ⬜ | `test/services/admin/scheduled_payout_enrichment_service_test.rb` | 1 |
| ⬜ | `test/services/admin/related_users_service_test.rb` | 1 |
| ⬜ | `test/services/admin/related_users_service_benchmark_test.rb` | 1 |
| ⬜ | `test/services/abn_validation_service_test.rb` | 1 |

## `test/sidekiq/` (77 files, 77 skips)

| Status | File | Skips |
|---|---|---:|
| ⬜ | `test/sidekiq/utm_link_sale_attribution_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/update_user_balance_stats_cache_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/update_taxonomy_stats_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/update_tax_rates_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/update_seller_refund_eligibility_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/update_sales_related_products_infos_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/update_purchasing_power_parity_factors_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/update_product_files_archive_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/update_payout_status_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/update_large_sellers_sales_count_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/update_integrations_on_tier_change_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/update_cached_sales_related_products_infos_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/update_bundle_purchases_content_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/unsubscribe_and_fail_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/transcode_video_for_streaming_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/sync_stuck_purchases_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/sync_stuck_payouts_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/suspend_users_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/suspend_accounts_with_payment_address_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/stripe_transfer_gumroads_available_balances_to_gumroads_bank_account_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/stripe_create_merchant_accounts_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/send_year_in_review_email_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/send_workflow_post_emails_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/send_workflow_installment_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/send_workflow_emails_to_past_canceled_members_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/send_wishlist_updated_emails_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/send_reminders_for_outstanding_user_compliance_info_requests_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/send_preorder_seller_summary_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/send_post_blast_emails_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/send_payment_reminder_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/send_memberships_price_update_emails_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/send_last_post_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/send_community_chat_recap_notifications_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/send_bundles_marketing_email_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/schedule_workflow_emails_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/schedule_membership_price_updates_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/schedule_abandoned_cart_emails_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/review_reminder_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/reports/generate_ytd_sales_report_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/remove_deleted_files_from_s3_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/reindex_recommendable_products_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/regenerate_sales_related_products_infos_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/refund_unpaid_purchases_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/recurring_charge_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/recurring_charge_reminder_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/recalculate_recent_wishlist_follower_count_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/push_notification_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/publish_scheduled_post_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/process_early_fraud_warning_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/post_to_ping_endpoints_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/post_to_individual_ping_endpoint_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/pdf_unstampable_notifier_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/log_sendgrid_event_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/log_resend_event_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/generate_subscribe_preview_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/exports/sales/process_chunk_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/exports/audience_export_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/exports/affiliate_export_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/elasticsearch_indexer_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/delete_stripe_apple_pay_domain_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/create_vat_report_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/create_us_states_sales_summary_report_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/create_us_state_monthly_sales_reports_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/create_stripe_apple_pay_domain_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/create_licenses_for_existing_customers_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/create_india_sales_report_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/create_global_sales_tax_summary_report_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/create_canada_monthly_sales_report_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/compile_gumroad_daily_analytics_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/collect_unclaimed_balances_of_inactive_stripe_accounts_job_test.rb` | 1 |
| ⬜ | `test/sidekiq/check_payment_address_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/charge_preorder_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/charge_declined_reminder_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/calculate_payout_numbers_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/cache_product_data_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/block_stripe_suspected_fraudulent_payments_worker_test.rb` | 1 |
| ⬜ | `test/sidekiq/annual_payout_export_worker_test.rb` | 1 |

## `test/presenters/` (62 files, 67 skips)

| Status | File | Skips |
|---|---|---:|
| ⬜ | `test/presenters/product_presenter/card_test.rb` | 5 |
| ⬜ | `test/presenters/product_review_presenter_test.rb` | 2 |
| ⬜ | `test/presenters/workflow_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/wishlist_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/utm_links_stats_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/utm_link_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/user_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/url_redirect_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/tax_center_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/settings_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/reviews_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/receipt_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/receipt_presenter/recommended_products_info_test.rb` | 1 |
| ⬜ | `test/presenters/receipt_presenter/payment_info_test.rb` | 1 |
| ⬜ | `test/presenters/receipt_presenter/mail_subject_test.rb` | 1 |
| ⬜ | `test/presenters/receipt_presenter/item_info_test.rb` | 1 |
| ⬜ | `test/presenters/receipt_presenter/giftee_manage_subscription_test.rb` | 1 |
| ⬜ | `test/presenters/receipt_presenter/footer_info_test.rb` | 1 |
| ⬜ | `test/presenters/receipt_presenter/charge_info_test.rb` | 1 |
| ⬜ | `test/presenters/purchase_product_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/public_file_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/profile_sections_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/profile_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/product_review_video_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/product_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/product_presenter/product_props_test.rb` | 1 |
| ⬜ | `test/presenters/product_presenter/installment_plan_props_test.rb` | 1 |
| ⬜ | `test/presenters/post_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/payouts_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/paginated_utm_links_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/paginated_product_posts_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/paginated_installments_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/library_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/invoice_presenter/supplier_info_test.rb` | 1 |
| ⬜ | `test/presenters/invoice_presenter/order_info_test.rb` | 1 |
| ⬜ | `test/presenters/invoice_presenter/form_info_test.rb` | 1 |
| ⬜ | `test/presenters/installment_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/dispute_evidence_page_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/discover/taxonomy_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/discover/autocomplete_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/dashboard_products_page_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/customers_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/customer_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/creator_home_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/comment_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/collaborators_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/collaborator_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/collab_products_page_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/checkout_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/checkout/upsells_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/checkout/form_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/checkout/discounts_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/cart_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/bundle_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/affiliates_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/affiliated_products_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/admin/user_presenter/card_test.rb` | 1 |
| ⬜ | `test/presenters/admin/unreviewed_user_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/admin/purchase_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/admin/product_presenter/card_test.rb` | 1 |
| ⬜ | `test/presenters/admin/payment_presenter_test.rb` | 1 |
| ⬜ | `test/presenters/admin/merchant_account_presenter_test.rb` | 1 |

## `test/modules/` (32 files, 32 skips)

| Status | File | Skips |
|---|---|---:|
| ⬜ | `test/modules/with_product_files_test.rb` | 1 |
| ⬜ | `test/modules/with_file_properties_test.rb` | 1 |
| ⬜ | `test/modules/user/stats_test.rb` | 1 |
| ⬜ | `test/modules/user/social_twitter_test.rb` | 1 |
| ⬜ | `test/modules/user/social_google_test.rb` | 1 |
| ⬜ | `test/modules/user/recommendations_test.rb` | 1 |
| ⬜ | `test/modules/user/posts_test.rb` | 1 |
| ⬜ | `test/modules/user/ping_notification_test.rb` | 1 |
| ⬜ | `test/modules/user/payout_schedule_test.rb` | 1 |
| ⬜ | `test/modules/user/payment_stats_test.rb` | 1 |
| ⬜ | `test/modules/user/money_balance_test.rb` | 1 |
| ⬜ | `test/modules/user/feature_status_test.rb` | 1 |
| ⬜ | `test/modules/user/compliance_test.rb` | 1 |
| ⬜ | `test/modules/user/async_devise_notification_test.rb` | 1 |
| ⬜ | `test/modules/subscription/ping_notification_test.rb` | 1 |
| ⬜ | `test/modules/s3_retrievable_test.rb` | 1 |
| ⬜ | `test/modules/purchase/targeting_test.rb` | 1 |
| ⬜ | `test/modules/purchase/risk_test.rb` | 1 |
| ⬜ | `test/modules/purchase/reviews_test.rb` | 1 |
| ⬜ | `test/modules/purchase/ping_notification_test.rb` | 1 |
| ⬜ | `test/modules/product/stats_test.rb` | 1 |
| ⬜ | `test/modules/product/searchable/search_test.rb` | 1 |
| ⬜ | `test/modules/product/searchable/offer_codes_test.rb` | 1 |
| ⬜ | `test/modules/product/searchable/name_field_search_test.rb` | 1 |
| ⬜ | `test/modules/product/searchable/indexing_test.rb` | 1 |
| ⬜ | `test/modules/product/searchable/filtered_search_test.rb` | 1 |
| ⬜ | `test/modules/product/review_stat_test.rb` | 1 |
| ⬜ | `test/modules/product/recommendations_test.rb` | 1 |
| ⬜ | `test/modules/product/prices_test.rb` | 1 |
| ⬜ | `test/modules/product/preview_test.rb` | 1 |
| ⬜ | `test/modules/product/caching_test.rb` | 1 |
| ⬜ | `test/modules/payment/stats_test.rb` | 1 |

## `test/business/` (25 files, 25 skips)

| Status | File | Skips |
|---|---|---:|
| ⬜ | `test/business/sales_tax/taxjar/taxjar_api_test.rb` | 1 |
| ⬜ | `test/business/sales_tax/sales_tax_calculator_test.rb` | 1 |
| ⬜ | `test/business/payments/payouts/processor/stripe/stripe_payout_processor_test.rb` | 1 |
| ⬜ | `test/business/payments/payouts/processor/paypal/paypal_payout_processor_test.rb` | 1 |
| ⬜ | `test/business/payments/payouts/payouts_test.rb` | 1 |
| ✅ | `test/business/payments/payouts/payout_estimates_test.rb` | 1 |
| ⬜ | `test/business/payments/merchant_registration/stripe/stripe_merchant_account_manager_test.rb` | 1 |
| ⬜ | `test/business/payments/merchant_registration/stripe/stripe_beneficial_owners_manager_test.rb` | 1 |
| ⬜ | `test/business/payments/merchant_registration/paypal/paypal_merchant_account_manager_test.rb` | 1 |
| ✅ | `test/business/payments/events/stripe/stripe_event_handler_test.rb` | 1 |
| ✅ | `test/business/payments/events/paypal/paypal_event_handler_test.rb` | 1 |
| ✅ | `test/business/payments/charging/implementations/stripe/stripe_chargeable_token_test.rb` | 0 |
| ✅ | `test/business/payments/charging/implementations/stripe/stripe_chargeable_payment_method_test.rb` | 0 |
| ✅ | `test/business/payments/charging/implementations/stripe/stripe_chargeable_credit_card_test.rb` | 0 |
| ✅ | `test/business/payments/charging/implementations/stripe/stripe_charge_radar_processor_test.rb` | 0 |
| ⬜ | `test/business/payments/charging/implementations/stripe/stripe_charge_processor_test.rb` | 1 |
| ✅ | `test/business/payments/charging/implementations/paypal/paypal_rest_api_test.rb` | 0 |
| ✅ | `test/business/payments/charging/implementations/paypal/paypal_charge_processor_test.rb` | 0 |
| ⬜ | `test/business/payments/charging/implementations/braintree/braintree_chargeable_transient_customer_test.rb` | 1 |
| ⬜ | `test/business/payments/charging/implementations/braintree/braintree_chargeable_nonce_test.rb` | 1 |
| ⬜ | `test/business/payments/charging/implementations/braintree/braintree_charge_test.rb` | 1 |
| ⬜ | `test/business/payments/charging/implementations/braintree/braintree_charge_refund_test.rb` | 1 |
| ⬜ | `test/business/payments/charging/implementations/braintree/braintree_charge_processor_test.rb` | 1 |
| ✅ | `test/business/payments/charging/chargeable_test.rb` | 0 |
| ✅ | `test/business/payments/charging/charge_processor_test.rb` | 0 |

## `test/mailers/` (9 files, 0 skips — all backfilled)

| Status | File | Skips |
|---|---|---:|
| ✅ | `test/mailers/one_off_mailer_test.rb` | 0 |
| ✅ | `test/mailers/customer_mailer_test.rb` | 0 |
| ✅ | `test/mailers/customer_low_priority_mailer_test.rb` | 0 |
| ✅ | `test/mailers/creator_mailer_test.rb` | 0 |
| ✅ | `test/mailers/contacting_creator_mailer_test.rb` | 0 |
| ✅ | `test/mailers/affiliate_request_mailer_test.rb` | 0 |
| ✅ | `test/mailers/affiliate_mailer_test.rb` | 0 |
| ✅ | `test/mailers/admin_mailer_test.rb` | 0 |
| ✅ | `test/mailers/accounting_mailer_test.rb` | 0 |

## `test/lib/` (6 files, 6 skips)

| Status | File | Skips |
|---|---|---:|
| ✅ | `test/lib/utilities/with_max_execution_time_test.rb` | 0 |
| ✅ | `test/lib/utilities/replica_lag_watcher_test.rb` | 0 |
| ✅ | `test/lib/utilities/geo_ip_test.rb` | 0 |
| ✅ | `test/lib/utilities/dev_tools_test.rb` | 0 |
| ✅ | `test/lib/js_error_reporter_test.rb` | 0 |
| ✅ | `test/lib/elasticsearch_setup_test.rb` | 0 |

## `test/observers/` (2 files, 2 skips)

| Status | File | Skips |
|---|---|---:|
| ✅ | `test/observers/email_delivery_observer/handle_email_event_test.rb` | 0 |
| ✅ | `test/observers/email_delivery_observer/handle_customer_email_info_test.rb` | 0 |

## `test/helpers/` (2 files, 2 skips)

| Status | File | Skips |
|---|---|---:|
| ✅ | `test/helpers/products_helper_test.rb` | 1 |
| ✅ | `test/helpers/payouts_helper_test.rb` | 1 |

## `test/policies/` (1 files, 1 skips)

| Status | File | Skips |
|---|---|---:|
| ✅ | `test/policies/comment_context_policy_test.rb` | 1 |

## `test/jobs/` (1 files, 1 skips)

| Status | File | Skips |
|---|---|---:|
| ✅ | `test/jobs/delete_unused_public_files_job_test.rb` | 1 |

## `test/root/` (1 files, 1 skips)

| Status | File | Skips |
|---|---|---:|

