# frozen_string_literal: true

# Stripe-mock magic card numbers used across edge-case tests.
# Source: https://stripe.com/docs/testing
#
# These constants exist so that test bodies read like English:
#
#   page.fill('input[name="cardnumber"]', StripeTestCards::INSUFFICIENT_FUNDS)
#
# Rather than:
#
#   page.fill('input[name="cardnumber"]', "4000000000009995")
#
# Add new magic numbers here, not inline in tests.
module StripeTestCards
  # ---------- Successful paths ----------
  VISA_SUCCESS         = "4242424242424242"
  MASTERCARD_SUCCESS   = "5555555555554444"
  AMEX_SUCCESS         = "378282246310005"

  # ---------- 3DS / SCA ----------
  REQUIRES_3DS_AUTH      = "4000002500003155"   # Authenticate → succeed
  REQUIRES_3DS_FAIL      = "4000008400001629"   # Authenticate → fail
  ALWAYS_AUTHENTICATES   = "4000002760003184"   # SCA on every charge
  EXEMPT_FROM_3DS        = "4242424242424242"   # Frictionless

  # ---------- Indian RBI mandate (recurring 3DS) ----------
  INDIA_RBI_MANDATE      = "4000003560000123"

  # ---------- Decline reasons ----------
  GENERIC_DECLINE        = "4000000000000002"
  INSUFFICIENT_FUNDS     = "4000000000009995"
  STOLEN_CARD            = "4000000000009979"
  LOST_CARD              = "4000000000009987"
  EXPIRED_CARD           = "4000000000000069"
  INCORRECT_CVC          = "4000000000000127"
  PROCESSING_ERROR       = "4000000000000119"

  # ---------- Risk / Radar ----------
  ALWAYS_BLOCK_RADAR     = "4100000000000019"
  ELEVATED_RISK          = "4000000000004954"

  # ---------- Rate limit / infra ----------
  TRIGGERS_RATE_LIMIT    = "4000000000000259"   # stripe-mock 429 simulator

  # ---------- Country-specific ----------
  UK_VISA                = "4000008260000000"
  GERMAN_BANCONTACT      = "4000002760003184"   # treat as DE-issued for tests
  JAPAN_JCB              = "3530111333300000"
end
