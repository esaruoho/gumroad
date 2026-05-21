# frozen_string_literal: true

class Charge::CreateService
  attr_accessor :order, :seller, :merchant_account, :chargeable, :purchases, :amount_cents, :gumroad_amount_cents,
                :setup_future_charges, :off_session, :statement_description, :charge, :mandate_options

  def initialize(order:, seller:, merchant_account:, chargeable:,
                 purchases:, amount_cents:, gumroad_amount_cents:,
                 setup_future_charges:, off_session:,
                 statement_description:, mandate_options: nil)
    @order = order
    @seller = seller
    @merchant_account = merchant_account
    @chargeable = chargeable
    @purchases = purchases
    @amount_cents = amount_cents
    @gumroad_amount_cents = gumroad_amount_cents
    @setup_future_charges = setup_future_charges
    @off_session = off_session
    @statement_description = statement_description
    @mandate_options = mandate_options
  end

  def perform
    self.charge = order.charges.find_or_create_by!(seller:)
    self.charge.update!(merchant_account:,
                        processor: merchant_account.charge_processor_id,
                        amount_cents:,
                        gumroad_amount_cents:,
                        payment_method_fingerprint: chargeable.fingerprint)

    purchases.each do |purchase|
      purchase.charge = charge
      charge.credit_card ||= purchase.credit_card
      purchase.save!
    end

    charge_intent = with_charge_processor_error_handler do
      # Determine charge currency: use buyer's local currency if set, else USD
      charge_currency = determine_charge_currency
      charge_amount = determine_charge_amount_cents
      # Convert Gumroad fee to charge currency — Stripe requires application_fee_amount
      # and transfer_data.amount in the same currency as the charge.
      # Use convert_price_raw (no smart rounding) since fees are internal amounts,
      # not consumer-facing price points.
      fee_amount = if charge_currency != "usd"
                     BuyerCurrencyService.convert_price_raw(
                       gumroad_amount_cents,
                       from_currency: "usd",
                       to_currency: charge_currency
                     )
                   else
                     gumroad_amount_cents
                   end
      ChargeProcessor.create_payment_intent_or_charge!(merchant_account,
                                                       chargeable,
                                                       charge_amount,
                                                       fee_amount,
                                                       "#{Charge::COMBINED_CHARGE_PREFIX}#{charge.external_id}",
                                                       "Gumroad Charge #{charge.external_id}",
                                                       statement_description:,
                                                       transfer_group: charge.id_with_prefix,
                                                       off_session:,
                                                       setup_future_charges:,
                                                       metadata: StripeMetadata.build_metadata_large_list(purchases.map(&:external_id), key: :purchases, separator: ","),
                                                       mandate_options:,
                                                       currency: charge_currency)
    end

    if charge_intent.present?
      charge.charge_intent = charge_intent
      charge.payment_method_fingerprint = chargeable.fingerprint
      charge.stripe_payment_intent_id = charge_intent.id if charge_intent.is_a? StripeChargeIntent
      charge.stripe_setup_intent_id = charge_intent.id if charge_intent.is_a? StripeSetupIntent

      if charge_intent.succeeded?
        charge.processor_transaction_id = charge_intent.charge.id
        charge.processor_fee_cents = charge_intent.charge.fee
        charge.processor_fee_currency = charge_intent.charge.fee_currency
      end

      charge.save!
    end
    charge
  end

  def with_charge_processor_error_handler
    yield
  rescue ChargeProcessorInvalidRequestError, ChargeProcessorUnavailableError => e
    logger.error "Charge processor error: #{e.message} in charge: #{charge.external_id}"
    purchases.each do |purchase|
      purchase.errors.add :base, "There is a temporary problem, please try again (your card was not charged)."
      purchase.error_code = charge_processor_unavailable_error
    end
    nil
  rescue ChargeProcessorPayeeAccountRestrictedError => e
    logger.error "Charge processor error: #{e.message} in charge: #{charge.external_id}"
    purchases.each do |purchase|
      purchase.errors.add :base, "There is a problem with creator's paypal account, please try again later (your card was not charged)."
      purchase.stripe_error_code = PurchaseErrorCode::PAYPAL_MERCHANT_ACCOUNT_RESTRICTED
    end
    nil
  rescue ChargeProcessorPayerCancelledBillingAgreementError => e
    logger.error "Error while creating charge: #{e.message} in charge: #{charge.external_id}"
    purchases.each do |purchase|
      purchase.errors.add :base, "Customer has cancelled the billing agreement on PayPal."
      purchase.stripe_error_code = PurchaseErrorCode::PAYPAL_PAYER_CANCELLED_BILLING_AGREEMENT
    end
    nil
  rescue ChargeProcessorPaymentDeclinedByPayerAccountError => e
    logger.error "Error while creating charge: #{e.message} in charge: #{charge.external_id}"
    purchases.each do |purchase|
      purchase.errors.add :base, "Customer PayPal account has declined the payment."
      purchase.stripe_error_code = PurchaseErrorCode::PAYPAL_PAYER_ACCOUNT_DECLINED_PAYMENT
    end
    nil
  rescue ChargeProcessorUnsupportedPaymentTypeError => e
    logger.info "Charge processor error: Unsupported paypal payment method selected"
    purchases.each do |purchase|
      purchase.errors.add :base, "We weren't able to charge your PayPal account. Please select another method of payment."
      purchase.stripe_error_code = e.error_code
      purchase.stripe_transaction_id = e.charge_id
    end
    nil
  rescue ChargeProcessorUnsupportedPaymentAccountError => e
    logger.info "Charge processor error: PayPal account used is not supported"
    purchases.each do |purchase|
      purchase.errors.add :base, "Your PayPal account cannot be charged. Please select another method of payment."
      purchase.stripe_error_code = e.error_code
      purchase.stripe_transaction_id = e.charge_id
    end
    nil
  rescue ChargeProcessorCardError => e
    purchases.each do |purchase|
      purchase.stripe_error_code = e.error_code
      purchase.stripe_transaction_id = e.charge_id
      purchase.was_zipcode_check_performed = true if e.error_code == "incorrect_zip"
      purchase.errors.add :base, PurchaseErrorCode.customer_error_message(e.message)
    end
    logger.info "Charge processor error: #{e.message} in charge: #{charge.external_id}"
    nil
  rescue ChargeProcessorErrorRateLimit => e
    purchases.each do |purchase|
      purchase.errors.add :base, "There is a temporary problem, please try again (your card was not charged)."
      purchase.error_code = charge_processor_unavailable_error
    end
    logger.error "Charge processor error: #{e.message} in charge: #{charge.external_id}"
    raise e
  rescue ChargeProcessorErrorGeneric => e
    purchases.each do |purchase|
      purchase.errors.add :base, "There is a temporary problem, please try again (your card was not charged)."
      purchase.stripe_error_code = e.error_code
    end
    logger.error "Charge processor error: #{e.message} in charge: #{charge.external_id}"
    nil
  end

  def charge_processor_unavailable_error
    if charge.processor.blank? || charge.processor == StripeChargeProcessor.charge_processor_id
      PurchaseErrorCode::STRIPE_UNAVAILABLE
    else
      PurchaseErrorCode::PAYPAL_UNAVAILABLE
    end
  end

  # Determine the Stripe charge currency. If all purchases in this charge group
  # share the same buyer_currency (set from IP geolocation), charge in that
  # currency for local presentment. Otherwise fall back to USD.
  def determine_charge_currency
    buyer_currencies = purchases.filter_map(&:buyer_currency).uniq
    if buyer_currencies.size == 1 && buyer_currencies.first.present?
      buyer_currencies.first
    else
      "usd"
    end
  end

  # Compute the charge amount in the buyer's currency.
  # When charging in a non-USD buyer currency, sum buyer_currency_amount_cents
  # (which includes the converted price + taxes + shipping in buyer currency).
  # Falls back to the USD total_transaction_cents when buyer currency is USD or unavailable.
  def determine_charge_amount_cents
    charge_currency = determine_charge_currency
    if charge_currency != "usd"
      purchases.sum { |p| p.buyer_currency_amount_cents || p.total_transaction_cents }
    else
      amount_cents
    end
  end
end
