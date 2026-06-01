# frozen_string_literal: true

module CurrencyHelper
  include BasePrice::Recurrence
  # Note: To reference a currency in code, use Currency::[3-char-ref].
  # e.g. Currency::USD, Currency::CAD

  COUNTRY_TO_CURRENCY = {
    "US" => "usd",
    "CA" => "cad",
    "GB" => "gbp",
    "IE" => "eur",
    "DE" => "eur",
    "FR" => "eur",
    "ES" => "eur",
    "IT" => "eur",
    "NL" => "eur",
    "BE" => "eur",
    "PT" => "eur",
    "AT" => "eur",
    "FI" => "eur",
    "GR" => "eur",
    "JP" => "jpy",
    "AU" => "aud",
    "CH" => "chf",
    "SE" => "sek",
    "NO" => "nok",
    "DK" => "dkk",
    "BR" => "brl",
    "MX" => "mxn",
    "IN" => "inr",
    "SG" => "sgd",
    "HK" => "hkd",
    "KR" => "krw",
    "NZ" => "nzd",
    "ZA" => "zar",
    "PL" => "pln",
    "CZ" => "czk",
    "HU" => "huf",
    "TR" => "try",
    "IL" => "ils",
    "AE" => "aed",
    "SA" => "sar",
    "TH" => "thb",
    "ID" => "idr",
    "PH" => "php",
    "MY" => "myr",
    "AR" => "ars",
  }.freeze
  BUYER_LOCAL_CURRENCY_RATE_TTL = 24.hours.to_i
  BUYER_LOCAL_CURRENCY_PREWARM_DEBOUNCE_TTL = 1.minute.to_i

  def currency_namespace
    Redis::Namespace.new(:currencies, redis: $redis)
  end

  def symbol_for(type = :usd)
    currency = CURRENCY_CHOICES[type.to_sym] || CURRENCY_CHOICES[:usd]
    currency[:symbol]
  end

  def min_price_for(type = :usd)
    currency = CURRENCY_CHOICES[type.to_sym] || CURRENCY_CHOICES[:usd]
    currency[:min_price]
  end

  def currency_choices
    CURRENCY_CHOICES.map { |k, v| [v[:display_format], k, v[:symbol]] }
  end

  def string_to_price_cents(currency_type, price_string)
    sanitized = price_string.to_s.delete(",")
    if sanitized.count(".") > 1
      first_dot = sanitized.index(".")
      sanitized = sanitized[0..first_dot] + sanitized[(first_dot + 1)..].delete(".")
    end
    sanitized = "0" unless sanitized.match?(/\d/)
    (BigDecimal(sanitized.presence || 0) * (is_currency_type_single_unit?(currency_type) ? 1 : 100)).round
  end

  def query_rate(currency_type)
    JSON.parse(URI.open(CURRENCY_SOURCE).read)["rates"][currency_type]
  rescue StandardError
    currency_namespace.get(currency_type.to_s)
  end

  def get_rate(currency_type)
    return "1.0" if currency_type.to_s == "usd" # Getting around an open exchange jankiness
    formatted_currency = currency_type.to_s.upcase
    rate = currency_namespace.get(formatted_currency.to_s)
    if rate && rate.to_f > 0
      rate.to_f.to_s
    else
      new_rate = query_rate(formatted_currency)
      currency_namespace.set(formatted_currency.to_s, new_rate)
      new_rate.to_f.to_s
    end
  end

  def buyer_currency_for_ip(ip)
    buyer_currency_for_country(GeoIp.lookup(ip)&.country_code)
  rescue StandardError
    nil
  end

  def buyer_currency_for_country(country_code)
    COUNTRY_TO_CURRENCY[country_code.to_s.upcase]
  end

  def buyer_local_price_cents(price_cents:, from_currency:, to_currency:, rate: nil)
    return price_cents if from_currency.to_s.casecmp?(to_currency.to_s)

    rate ||= buyer_local_currency_rate(from_currency:, to_currency:)
    return if rate.blank?

    from_subunit_to_unit = subunit_to_unit(from_currency)
    to_subunit_to_unit = subunit_to_unit(to_currency)
    ((BigDecimal(price_cents.to_s) / from_subunit_to_unit) * rate * to_subunit_to_unit).round
  rescue StandardError
    nil
  end

  def buyer_local_currency_rate(from_currency:, to_currency:)
    from_currency = from_currency.to_s.downcase
    to_currency = to_currency.to_s.downcase
    return BigDecimal("1") if from_currency == to_currency

    cache_key = buyer_local_currency_rate_cache_key(from_currency:, to_currency:, date: Date.current)
    cached_rate = currency_namespace.get(cache_key)
    return BigDecimal(cached_rate) if cached_rate.present? && cached_rate.to_d.positive?

    # On cold cache: fall back to last known good rate (stale-while-revalidate) and enqueue
    # a background refresh. We never make a synchronous HTTP call on the render path.
    # Debounce the enqueue with a short-lived NX key so a traffic spike right after the daily
    # cache expires doesn't fire perform_async (and its dedup-digest round-trip) on every render.
    enqueue_prewarm_buyer_local_currency_rate(from_currency:, to_currency:)

    stale_rate = currency_namespace.get(buyer_local_currency_stale_rate_cache_key(from_currency:, to_currency:))
    BigDecimal(stale_rate) if stale_rate.present? && stale_rate.to_d.positive?
  end

  # Synchronous path used by background jobs (cron + prewarm). Safe to block on HTTP here.
  def refresh_buyer_local_currency_rate!(from_currency:, to_currency:)
    from_currency = from_currency.to_s.downcase
    to_currency = to_currency.to_s.downcase
    return BigDecimal("1") if from_currency == to_currency

    rate = query_buyer_local_currency_rate(from_currency:, to_currency:)
    return nil if rate.blank? || !rate.to_d.positive?

    cache_key = buyer_local_currency_rate_cache_key(from_currency:, to_currency:, date: Date.current)
    currency_namespace.set(cache_key, rate.to_s, ex: BUYER_LOCAL_CURRENCY_RATE_TTL)
    currency_namespace.set(buyer_local_currency_stale_rate_cache_key(from_currency:, to_currency:), rate.to_s)
    rate.to_d
  rescue StandardError
    nil
  end

  def buyer_currency_display_props(product:, price_cents:, ip:)
    product_currency = product.price_currency_type.to_s.downcase
    creator_opted_in = product.user.show_buyer_local_currency?

    default_props = {
      product_id: product.external_id,
      creator_opted_in:,
      buyer_currency_shown: product_currency,
      product_currency:,
      buyer_local_price_cents: nil,
      rate: nil,
      variant: "default",
    }

    return default_props unless creator_opted_in

    buyer_currency = buyer_currency_for_ip(ip)
    return default_props unless buyer_currency.present? && buyer_currency != product_currency

    rate = buyer_local_currency_rate(from_currency: product_currency, to_currency: buyer_currency)
    return default_props if rate.blank?

    local_price_cents = buyer_local_price_cents(
      price_cents:,
      from_currency: product_currency,
      to_currency: buyer_currency,
      rate:
    )
    return default_props if local_price_cents.blank?

    {
      product_id: product.external_id,
      creator_opted_in:,
      buyer_currency_shown: buyer_currency,
      product_currency:,
      buyer_local_price_cents: local_price_cents,
      rate: rate.to_f,
      variant: "buyer_local",
    }
  rescue StandardError
    # Graceful degradation: never re-run the operations that may have raised
    # (product.user.show_buyer_local_currency?, price_currency_type) — return a
    # static safe default so the product page renders without local-currency display.
    {
      product_id: product.external_id,
      creator_opted_in: false,
      buyer_currency_shown: nil,
      product_currency: nil,
      buyer_local_price_cents: nil,
      rate: nil,
      variant: "default",
    }
  end

  def buyer_local_price_props(product:, original_price_cents: nil, buyer_currency_display:)
    return {} unless buyer_currency_display&.dig(:variant) == "buyer_local"

    buyer_currency = buyer_currency_display[:buyer_currency_shown]
    rate = BigDecimal(buyer_currency_display[:rate].to_s)
    minor_unit_rate = rate *
      BigDecimal(subunit_to_unit(buyer_currency).to_s) /
      BigDecimal(subunit_to_unit(product.price_currency_type).to_s)
    props = {
      buyer_currency:,
      buyer_local_currency_rate: minor_unit_rate.to_f,
      buyer_local_currency_subunit_to_unit: subunit_to_unit(buyer_currency),
      buyer_local_price_cents: buyer_currency_display[:buyer_local_price_cents],
    }

    if original_price_cents.present?
      local_original_price_cents = buyer_local_price_cents(
        price_cents: original_price_cents,
        from_currency: product.price_currency_type,
        to_currency: buyer_currency,
        rate:
      )
      props[:buyer_local_original_price_cents] = local_original_price_cents if local_original_price_cents.present?
    end

    props
  end

  def get_usd_cents(currency_type, quantity, rate: nil)
    return quantity if currency_type.to_s == "usd" # Getting around an open exchange jankiness
    rate = get_rate(currency_type) if rate.nil?
    converted = BigDecimal(quantity) / rate.to_f
    if is_currency_type_single_unit?(currency_type)
      (converted * 100).round
    else
      converted.round
    end
  end

  # Converts USD cents to desired currency. Providing an optional explicit rate overrides the rate lookup by currency type
  #
  # currency_type - currency type denoted by abbreviated string
  # quantity - amount in USD cents
  # rate - optional. Uses this as the conversion rate instead of looking up by currency_type if present.
  def usd_cents_to_currency(currency_type, quantity, rate = nil)
    return quantity if currency_type.to_s == "usd" # Getting around an open exchange jankiness
    conversion_rate = rate.present? ? rate.to_f : get_rate(currency_type).to_f
    converted = BigDecimal(quantity) * conversion_rate
    if is_currency_type_single_unit?(currency_type)
      (converted / 100).round
    else
      converted.round
    end
  end

  def formatted_dollar_amount(amount_cents, with_currency: false, no_cents_if_whole: true)
    Money.new(amount_cents, "USD").format(with_currency:, no_cents_if_whole:)
  end

  def formatted_amount_in_currency(amount_cents, currency, no_cents_if_whole: true)
    Money.new(amount_cents, currency).format(symbol: false, no_cents_if_whole:, with_currency: true)
  end

  def format_just_price_in_cents(amount_cents, currency)
    price = formatted_price(currency, amount_cents)
    price == "$0.99" ? "99¢" : price
  end

  def formatted_price_with_recurrence(formatted_price, recurrence, charge_occurrence_count, format:)
    if recurrence
      formatted_price = \
        if format == :short
          "#{formatted_price} #{recurrence_short_indicator(recurrence)}"
        elsif format == :long
          "#{formatted_price} #{recurrence_long_indicator(recurrence)}"
        end
    end
    formatted_price += " x #{charge_occurrence_count}" if charge_occurrence_count.present?
    formatted_price
  end

  def formatted_price_in_currency_with_recurrence(amount_cents, currency, recurrence, charge_occurrence_count)
    formatted_price = format_just_price_in_cents(amount_cents, currency)
    formatted_price_with_recurrence(formatted_price, recurrence, charge_occurrence_count, format: :long)
  end

  def get_currency_by_type(currency_type)
    CURRENCY_CHOICES[currency_type.to_s.downcase] || CURRENCY_CHOICES["usd"]
  end

  def unit_scaling_factor(currency_type)
    is_currency_type_single_unit?(currency_type) ? 1 : 100
  end

  def is_currency_type_single_unit?(currency_type = "usd")
    get_currency_by_type(currency_type).key?("single_unit")
  end

  def formatted_price(currency_type, price)
    MoneyFormatter.format(price, currency_type.to_s.downcase.to_sym, no_cents_if_whole: true, symbol: true)
  end

  # Should match PriceTag component
  def product_card_formatted_price(price:, currency_code:, is_pay_what_you_want:, recurrence:, duration_in_months:)
    recurrence_label = recurrence_label(recurrence, duration_in_months)
    safe_join(
      [
        formatted_price(currency_code, price),
        (is_pay_what_you_want ? "+" : nil),
        (recurrence_label ? " #{recurrence_label}" : nil),
      ].compact
    )
  end

  # Should match formatRecurrenceWithDuration
  def recurrence_label(recurrence, duration_in_months)
    return if recurrence.blank?
    number_of_months = BasePrice::Recurrence.number_of_months_in_recurrence(recurrence)
    base_formatted_label = recurrence_long_indicator(recurrence)
    return base_formatted_label if duration_in_months.blank?

    "#{base_formatted_label} x #{(duration_in_months / number_of_months).round}"
  end

  def query_buyer_local_currency_rate(from_currency:, to_currency:)
    # Called only from the cache refresh path, not directly while rendering product pages.
    rates = JSON.parse(URI.open(CURRENCY_SOURCE).read)["rates"]
    from_rate = from_currency.to_s.casecmp?(Currency::USD) ? BigDecimal("1") : BigDecimal(rates[from_currency.to_s.upcase].to_s)
    to_rate = to_currency.to_s.casecmp?(Currency::USD) ? BigDecimal("1") : BigDecimal(rates[to_currency.to_s.upcase].to_s)
    return if from_rate.blank? || !from_rate.positive? || to_rate.blank? || !to_rate.positive?

    to_rate / from_rate
  end

  def buyer_local_currency_rate_cache_key(from_currency:, to_currency:, date:)
    "buyer_local_currency_rate:#{from_currency}:#{to_currency}:#{date}"
  end

  def buyer_local_currency_stale_rate_cache_key(from_currency:, to_currency:)
    "buyer_local_currency_rate:#{from_currency}:#{to_currency}:latest"
  end

  def buyer_local_currency_prewarm_debounce_cache_key(from_currency:, to_currency:)
    "buyer_local_currency_rate:#{from_currency}:#{to_currency}:prewarm_enqueued"
  end

  def enqueue_prewarm_buyer_local_currency_rate(from_currency:, to_currency:)
    debounce_key = buyer_local_currency_prewarm_debounce_cache_key(from_currency:, to_currency:)
    return unless currency_namespace.set(debounce_key, "1", nx: true, ex: BUYER_LOCAL_CURRENCY_PREWARM_DEBOUNCE_TTL)

    PrewarmBuyerLocalCurrencyRateJob.perform_async(from_currency, to_currency)
  end

  def subunit_to_unit(currency_type)
    Money::Currency.new(currency_type.to_s.downcase).subunit_to_unit
  end
end
