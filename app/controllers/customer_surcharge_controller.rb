# frozen_string_literal: true

class CustomerSurchargeController < ApplicationController
  include CurrencyHelper

  def calculate_all
    products = params.require(:products)
    vat_id_valid = false
    has_vat_id_input = false
    shipping_rate = 0
    tax_rate = 0
    tax_included_rate = 0
    subtotal = 0
    buyer_currency = params[:buyer_currency].to_s.downcase.presence if Flipper.enabled?(:multi_currency_checkout)
    buyer_currency_supported = buyer_currency.present?
    products.each do |item|
      product = Link.find_by_unique_permalink(item[:permalink])
      next unless product
      if buyer_currency.present?
        merchant_account = product.user&.merchant_account(StripeChargeProcessor.charge_processor_id) ||
          MerchantAccount.gumroad(StripeChargeProcessor.charge_processor_id)
        buyer_currency_supported &&= MultiCurrency::MerchantCompatibility.supports_buyer_currency?(merchant_account, buyer_currency)
      end
      surcharges = calculate_surcharges(product, item[:quantity], item[:price].to_d.to_i, subscription_id: item[:subscription_id], recommended_by: item[:recommended_by])
      next unless surcharges
      tax_result = surcharges[:sales_tax_result]
      vat_id_valid = tax_result.business_vat_status == :valid
      has_vat_id_input ||= tax_result.to_hash[:has_vat_id_input]
      shipping_rate += get_usd_cents(product.price_currency_type, surcharges[:shipping_rate])
      tax_cents = tax_result.tax_cents
      if tax_cents > 0
        tax_rate += tax_cents
      end
      subtotal += tax_result.price_cents
    end
    total_cents = subtotal.round.to_i + tax_rate.round.to_i + shipping_rate.round.to_i
    buyer_currency_total_cents = if buyer_currency.present? && buyer_currency != Currency::USD && buyer_currency_supported
      BuyerCurrencyService.convert_price_raw(total_cents, from_currency: Currency::USD, to_currency: buyer_currency)
    end

    render json: {
      vat_id_valid:,
      has_vat_id_input:,
      shipping_rate_cents: shipping_rate,
      tax_cents: tax_rate.round.to_i,
      tax_included_cents: tax_included_rate.round.to_i,
      subtotal: subtotal.round.to_i,
      buyer_currency: buyer_currency_supported ? buyer_currency : nil,
      buyer_currency_total_cents:
    }
  rescue CurrencyHelper::CurrencyRateUnavailable
    render json: {
      vat_id_valid:,
      has_vat_id_input:,
      shipping_rate_cents: shipping_rate,
      tax_cents: tax_rate.round.to_i,
      tax_included_cents: tax_included_rate.round.to_i,
      subtotal: subtotal.round.to_i,
      buyer_currency: nil,
      buyer_currency_total_cents: nil
    }
  end

  private
    def calculate_surcharges(product, quantity, price, subscription_id: nil, recommended_by: nil)
      if subscription_id.present?
        subscription = Subscription.find_by_external_id(subscription_id)
        return nil unless subscription&.original_purchase.present?
      end

      sales_tax_info = subscription&.original_purchase&.purchase_sales_tax_info
      if sales_tax_info.present?
        buyer_location = {
          postal_code: sales_tax_info.postal_code,
          country: sales_tax_info.country_code,
          ip_address: sales_tax_info.ip_address,
          state: sales_tax_info.state_code || GeoIp.lookup(sales_tax_info.ip_address)&.region_name,
        }
        buyer_vat_id = sales_tax_info.business_vat_id
        from_discover = subscription.original_purchase.was_discover_fee_charged?
      else
        buyer_location = { postal_code: params[:postal_code], country: params[:country], state: params[:state], ip_address: request.remote_ip }
        buyer_vat_id = params[:vat_id].presence

        from_discover = recommended_by.present?
      end

      shipping_destination = ShippingDestination.for_product_and_country_code(product:, country_code: params[:country])
      shipping_rate = shipping_destination&.calculate_shipping_rate(quantity:) || 0

      sales_tax_result = SalesTaxCalculator.new(product:,
                                                price_cents: price,
                                                shipping_cents: shipping_rate,
                                                quantity:,
                                                buyer_location:,
                                                buyer_vat_id:,
                                                from_discover:).calculate

      { sales_tax_result:, shipping_rate: }
    end
end
