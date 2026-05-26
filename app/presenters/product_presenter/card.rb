# frozen_string_literal: true

class ProductPresenter::Card
  include Rails.application.routes.url_helpers
  include ProductsHelper
  include CurrencyHelper

  ASSOCIATIONS = [
    :alive_prices, :product_review_stat, :default_offer_code, :skus,
    {
      tiers: :alive_prices,
      user: [:avatar_attachment, :avatar_blob, :custom_domain],
      variant_categories_alive: :alive_variants,
      thumbnail_alive: { file_attachment: { blob: { variant_records: { image_attachment: :blob } } } },
      display_asset_previews: [:file_attachment, :file_blob],
    }
  ]

  attr_reader :product

  def initialize(product:)
    @product = product
  end

  def for_web(request: nil, recommended_by: nil, recommender_model_name: nil, target: nil, show_seller: true, affiliate_id: nil, query: nil, offer_code: nil, compute_description: true, compute_inventory: true)
    default_recurrence = product.default_price_recurrence
    base_price_cents = product.display_price_cents(for_default_duration: true)
    price_cents = compute_discounted_price_cents(base_price_cents)
    original_price_cents = price_cents < base_price_cents ? base_price_cents : nil

    props = {
      id: product.external_id,
      permalink: product.unique_permalink,
      name: product.name,
      seller: show_seller ? UserPresenter.new(user: product.user).author_byline_props(recommended_by:) : nil,
      ratings: product.display_product_reviews? ? {
        count: product.reviews_count,
        average: product.average_rating,
      } : nil,
      thumbnail_url: product.thumbnail_or_cover_url,
      native_type: product.native_type,
      quantity_remaining: compute_inventory ? product.remaining_for_sale_count : nil,
      is_sales_limited: compute_inventory ? product.max_purchase_count? : false,
      price_cents:,
      currency_code: product.price_currency_type.downcase,
      **buyer_local_price_props(price_cents:, original_price_cents:, request:),
      is_pay_what_you_want: product.has_customizable_price_option?,
      url: url_for_product_page(product, request:, recommended_by:, recommender_model_name:, layout: target, affiliate_id:, query:, offer_code:),
      duration_in_months: product.duration_in_months,
      recurrence: default_recurrence&.recurrence,
    }

    # Include base_price_cents when there's a discount to show original price with strikethrough
    props[:original_price_cents] = original_price_cents if original_price_cents.present?

    if compute_description
      props[:description] = product.plaintext_description.truncate(100)
    end

    props
  end

  def for_email
    {
      name: product.name,
      thumbnail_url: product.for_email_thumbnail_url,
      url: product.long_url,
      seller: {
        name: product.user.display_name,
        profile_url: product.user.profile_url,
        avatar_url: product.user.avatar_url,
      },
    }
  end

  private
    def compute_discounted_price_cents(base_price_cents)
      offer_code = product.default_offer_code
      return base_price_cents if offer_code.blank? || offer_code.inactive?
      return base_price_cents if offer_code.existing_customers_only?

      discount_amount_cents = offer_code.amount_off(base_price_cents)
      [base_price_cents - discount_amount_cents, 0].max
    end

    def buyer_local_price_props(price_cents:, original_price_cents: nil, request:)
      return {} unless request.present? && product.user.show_buyer_local_currency?

      buyer_currency = buyer_currency_for_ip(request.remote_ip)
      return {} if buyer_currency == product.price_currency_type.to_s.downcase

      local_price_cents = buyer_local_price_cents(
        price_cents:,
        from_currency: product.price_currency_type,
        to_currency: buyer_currency
      )
      return {} if local_price_cents.blank?

      props = {
        buyer_currency:,
        buyer_local_price_cents: local_price_cents,
      }

      if original_price_cents.present?
        local_original_price_cents = buyer_local_price_cents(
          price_cents: original_price_cents,
          from_currency: product.price_currency_type,
          to_currency: buyer_currency
        )
        props[:buyer_local_original_price_cents] = local_original_price_cents if local_original_price_cents.present?
      end

      props
    end
end
