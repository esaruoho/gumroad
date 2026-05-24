# frozen_string_literal: true

require "test_helper"

class DisputeEvidence::GenerateUncategorizedTextServiceTest < ActiveSupport::TestCase
  test ".perform returns customer location, billing postal code, and previous purchases information" do
    disputed_purchase, = purchase_pair_with_matching_fingerprint

    expected_uncategorized_text = <<~TEXT.strip_heredoc.rstrip
      Device location: California, United States
      Billing postal code: 12345

      Previous undisputed purchase on Gumroad:
      2023-12-31 00:00:00 UTC, $12.99, John Doe, other_email@example.com, Billing postal code: 99999, Device location: 1.1.1.1, Oregon, United States
    TEXT

    assert_equal expected_uncategorized_text, DisputeEvidence::GenerateUncategorizedTextService.perform(disputed_purchase)
  end

  test ".perform does not include previous purchases information when the fingerprint differs" do
    disputed_purchase, other_purchase = purchase_pair_with_matching_fingerprint
    other_purchase.update_columns(stripe_fingerprint: "other_fingerprint")

    expected_uncategorized_text = <<~TEXT.strip_heredoc.rstrip
      Device location: California, United States
      Billing postal code: 12345
    TEXT

    assert_equal expected_uncategorized_text, DisputeEvidence::GenerateUncategorizedTextService.perform(disputed_purchase)
  end

  private
    def purchase_pair_with_matching_fingerprint
      disputed_purchase = purchases(:named_seller_call_purchase)
      other_purchase = purchases(:another_seller_call_purchase)

      disputed_purchase.update_columns(
        email: "customer@example.com",
        full_name: "Joe Doe",
        ip_state: "California",
        ip_country: "United States",
        credit_card_zipcode: "12345",
        stripe_fingerprint: "sample_fingerprint",
        purchase_state: "successful"
      )

      other_purchase.update_columns(
        created_at: Time.utc(2023, 12, 31),
        total_transaction_cents: 1299,
        email: "other_email@example.com",
        full_name: "John Doe",
        ip_state: "Oregon",
        ip_country: "United States",
        credit_card_zipcode: "99999",
        ip_address: "1.1.1.1",
        stripe_fingerprint: "sample_fingerprint",
        purchase_state: "successful",
        stripe_refunded: false,
        chargeback_date: nil
      )

      [disputed_purchase, other_purchase]
    end
end
