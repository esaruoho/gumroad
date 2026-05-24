# frozen_string_literal: true

require "test_helper"

class PaypalChargeTest < ActiveSupport::TestCase
  ORDER_DETAILS = {
    "id" => "426572068V1934255",
    "intent" => "CAPTURE",
    "purchase_units" => [
      {
        "reference_id" => "P5ppE6H8XIjy2JSCgUhbAw==",
        "amount" => {
          "currency_code" => "USD",
          "value" => "19.50",
          "breakdown" => {
            "item_total" => { "currency_code" => "USD", "value" => "15.00" },
            "shipping" => { "currency_code" => "USD", "value" => "3.00" },
            "handling" => { "currency_code" => "USD", "value" => "0.00" },
            "tax_total" => { "currency_code" => "USD", "value" => "1.50" },
            "insurance" => { "currency_code" => "USD", "value" => "0.00" },
            "shipping_discount" => { "currency_code" => "USD", "value" => "0.00" },
            "discount" => { "currency_code" => "USD", "value" => "0.00" }
          }
        },
        "payee" => {
          "email_address" => "sb-c7jpx2385730@business.example.com",
          "merchant_id" => "MN7CSWD6RCNJ8"
        },
        "payment_instruction" => {
          "platform_fees" => [
            {
              "amount" => { "currency_code" => "USD", "value" => "0.75" },
              "payee" => {
                "email_address" => "paypal-api-facilitator@gumroad.com",
                "merchant_id" => "HU29XVVCZXNFN"
              }
            }
          ]
        },
        "description" => "The Works of Edgar Gumstein",
        "soft_descriptor" => "PAYPAL *JOHNDOESTES YO",
        "items" => [
          {
            "name" => "The Works of Edgar Gumstein",
            "unit_amount" => { "currency_code" => "USD", "value" => "5.00" },
            "tax" => { "currency_code" => "USD", "value" => "0.00" },
            "quantity" => "3",
            "sku" => "aa"
          }
        ],
        "shipping" => {
          "name" => { "full_name" => "Gumbot Gumstein" },
          "address" => {
            "address_line_1" => "1 Main St",
            "admin_area_2" => "San Jose",
            "admin_area_1" => "CA",
            "postal_code" => "95131",
            "country_code" => "US"
          }
        },
        "payments" => {
          "captures" => [
            {
              "id" => "58003532R80972514",
              "status" => "REFUNDED",
              "amount" => { "currency_code" => "USD", "value" => "19.50" },
              "final_capture" => true,
              "disbursement_mode" => "INSTANT",
              "seller_protection" => {
                "status" => "ELIGIBLE",
                "dispute_categories" => [{}, {}]
              },
              "seller_receivable_breakdown" => {
                "gross_amount" => { "currency_code" => "USD", "value" => "19.50" },
                "paypal_fee" => { "currency_code" => "USD", "value" => "0.87" },
                "platform_fees" => [
                  {
                    "amount" => { "currency_code" => "USD", "value" => "0.75" },
                    "payee" => { "merchant_id" => "HU29XVVCZXNFN" }
                  }
                ],
                "net_amount" => { "currency_code" => "USD", "value" => "17.88" }
              },
              "create_time" => "2020-06-26T17:42:28Z",
              "update_time" => "2020-06-26T19:23:02Z"
            }
          ],
          "refunds" => [
            {
              "id" => "8A762400SC645253S",
              "amount" => { "currency_code" => "USD", "value" => "19.50" },
              "seller_payable_breakdown" => {
                "gross_amount" => { "currency_code" => "USD", "value" => "19.50" },
                "paypal_fee" => { "currency_code" => "USD", "value" => "0.57" },
                "platform_fees" => [
                  { "amount" => { "currency_code" => "USD", "value" => "0.75" } }
                ],
                "net_amount" => { "currency_code" => "USD", "value" => "18.18" },
                "total_refunded_amount" => { "currency_code" => "USD", "value" => "19.50" }
              },
              "status" => "COMPLETED",
              "create_time" => "2020-06-26T12:23:02-07:00",
              "update_time" => "2020-06-26T12:23:02-07:00"
            }
          ]
        }
      }
    ],
    "payer" => {
      "name" => { "given_name" => "Gumbot", "surname" => "Gumstein" },
      "email_address" => "paypal-gr-integspecs@gumroad.com",
      "payer_id" => "92SVVJSWYT72E",
      "phone" => { "phone_number" => { "national_number" => "4085146918" } },
      "address" => { "country_code" => "US" }
    },
    "update_time" => "2020-06-26T19:23:02Z",
    "status" => "COMPLETED"
  }.freeze

  test "order api: sets all the properties of the order" do
    charge = PaypalCharge.new(paypal_transaction_id: "58003532R80972514",
                              order_api_used: true,
                              payment_details: ORDER_DETAILS)

    assert_equal PaypalChargeProcessor.charge_processor_id, charge.charge_processor_id
    assert_equal "58003532R80972514", charge.id
    assert_equal 87.0, charge.fee
    assert_equal "REFUNDED", charge.paypal_payment_status
    assert_equal true, charge.refunded
    assert_nil charge.flow_of_funds
    assert_equal "paypal_paypal-gr-integspecs@gumroad.com", charge.card_fingerprint
    assert_equal "US", charge.card_country
    assert_equal "paypal", charge.card_type
    assert_equal "paypal-gr-integspecs@gumroad.com", charge.card_visual
  end

  test "order api: does not throw error if paypal_fee value is absent" do
    payment_details = Marshal.load(Marshal.dump(ORDER_DETAILS))
    payment_details["purchase_units"][0]["payments"]["captures"][0]["seller_receivable_breakdown"].delete("paypal_fee")

    charge = PaypalCharge.new(paypal_transaction_id: "58003532R80972514",
                              order_api_used: true,
                              payment_details:)

    assert_equal PaypalChargeProcessor.charge_processor_id, charge.charge_processor_id
    assert_equal "58003532R80972514", charge.id
    assert_nil charge.fee
    assert_equal "REFUNDED", charge.paypal_payment_status
    assert_equal true, charge.refunded
    assert_nil charge.flow_of_funds
    assert_equal "paypal_paypal-gr-integspecs@gumroad.com", charge.card_fingerprint
    assert_equal "US", charge.card_country
    assert_equal "paypal", charge.card_type
    assert_equal "paypal-gr-integspecs@gumroad.com", charge.card_visual
  end

  test "order api: when paypal transaction is not present, doesn't set order API property" do
    charge = PaypalCharge.new(paypal_transaction_id: nil, order_api_used: true)
    assert_equal PaypalChargeProcessor.charge_processor_id, charge.charge_processor_id
    assert_nil charge.id
    assert_nil charge.fee
    assert_nil charge.paypal_payment_status
    assert_nil charge.refunded
    assert_nil charge.flow_of_funds
    assert_nil charge.card_fingerprint
    assert_nil charge.card_country
    assert_nil charge.card_type
    assert_nil charge.card_visual
  end

  def build_paypal_payment_info(status: PaypalApiPaymentStatus::REFUNDED)
    info = PayPal::SDK::Merchant::DataTypes::PaymentInfoType.new
    info.PaymentStatus = status
    info.GrossAmount.value = "10.00"
    info.GrossAmount.currencyID = "USD"
    info.FeeAmount.value = "1.00"
    info.FeeAmount.currencyID = "USD"
    info
  end

  def build_paypal_payer_info
    payer = PayPal::SDK::Merchant::DataTypes::PayerInfoType.new
    payer.Payer = "paypal-buyer@gumroad.com"
    payer.PayerID = "sample-fingerprint-source"
    payer.PayerCountry = Compliance::Countries::USA.alpha2
    payer
  end

  test "express checkout: populates the required payment info and optional payer info" do
    paypal_charge = PaypalCharge.new(paypal_transaction_id: "5SP884803B810025T",
                                     order_api_used: false,
                                     payment_details: {
                                       paypal_payment_info: build_paypal_payment_info,
                                       paypal_payer_info: build_paypal_payer_info
                                     })

    refute_nil paypal_charge
    assert_equal "5SP884803B810025T", paypal_charge.id
    assert_equal true, paypal_charge.refunded
    assert_equal "Refunded", paypal_charge.paypal_payment_status
    assert_equal 100, paypal_charge.fee
    assert_equal "paypal_sample-fingerprint-source", paypal_charge.card_fingerprint
    assert_equal CardType::PAYPAL, paypal_charge.card_type
    assert_equal Compliance::Countries::USA.alpha2, paypal_charge.card_country
  end

  test "express checkout: populates the required payment and does not set payer fields if payload is not passed in" do
    paypal_charge = PaypalCharge.new(paypal_transaction_id: "5SP884803B810025T",
                                     order_api_used: false,
                                     payment_details: {
                                       paypal_payment_info: build_paypal_payment_info
                                     })

    refute_nil paypal_charge
    assert_equal "5SP884803B810025T", paypal_charge.id
    assert_equal true, paypal_charge.refunded
    assert_equal "Refunded", paypal_charge.paypal_payment_status
    assert_equal 100, paypal_charge.fee
    assert_nil paypal_charge.card_fingerprint
    assert_nil paypal_charge.card_type
    assert_nil paypal_charge.card_country
  end

  test "express checkout: sets the refund states based on the PayPal PaymentInfo PaymentStatus" do
    info = build_paypal_payment_info(status: PaypalApiPaymentStatus::COMPLETED)
    charge = PaypalCharge.new(paypal_transaction_id: "5SP884803B810025T",
                              order_api_used: false,
                              payment_details: { paypal_payment_info: info })
    assert_equal false, charge.refunded
    assert_equal "Completed", charge.paypal_payment_status

    info.PaymentStatus = "Refunded"
    charge = PaypalCharge.new(paypal_transaction_id: "5SP884803B810025T",
                              order_api_used: false,
                              payment_details: { paypal_payment_info: info })
    assert_equal true, charge.refunded

    info.PaymentStatus = PaypalApiPaymentStatus::REVERSED
    charge = PaypalCharge.new(paypal_transaction_id: "5SP884803B810025T",
                              order_api_used: false,
                              payment_details: { paypal_payment_info: info })
    assert_equal false, charge.refunded
  end

  test "express checkout: does not have a flow of funds" do
    charge = PaypalCharge.new(paypal_transaction_id: "5SP884803B810025T",
                              order_api_used: false,
                              payment_details: { paypal_payment_info: build_paypal_payment_info })
    assert_nil charge.flow_of_funds
  end
end
