# frozen_string_literal: true

# Detects the buyer's preferred currency from their IP-based country,
# converts seller prices into that currency, and applies Apple-style
# smart rounding for psychologically appealing price points.
class BuyerCurrencyService
  include CurrencyHelper

  # Maps ISO 3166-1 alpha-2 country codes to supported Gumroad currency codes.
  # Only countries whose currency is in CURRENCY_CHOICES get local presentment;
  # everyone else falls back to the seller's currency.
  COUNTRY_TO_CURRENCY = {
    # USD
    "US" => "usd", "EC" => "usd", "SV" => "usd", "PA" => "usd",
    "PR" => "usd", "GU" => "usd", "VI" => "usd", "AS" => "usd",
    # GBP
    "GB" => "gbp", "GG" => "gbp", "JE" => "gbp", "IM" => "gbp",
    # EUR
    "DE" => "eur", "FR" => "eur", "IT" => "eur", "ES" => "eur",
    "NL" => "eur", "BE" => "eur", "AT" => "eur", "IE" => "eur",
    "PT" => "eur", "FI" => "eur", "GR" => "eur", "SK" => "eur",
    "SI" => "eur", "EE" => "eur", "LV" => "eur", "LT" => "eur",
    "LU" => "eur", "MT" => "eur", "CY" => "eur", "HR" => "eur",
    # JPY
    "JP" => "jpy",
    # INR
    "IN" => "inr",
    # AUD
    "AU" => "aud",
    # CAD
    "CA" => "cad",
    # HKD
    "HK" => "hkd",
    # SGD
    "SG" => "sgd",
    # TWD
    "TW" => "twd",
    # NZD
    "NZ" => "nzd",
    # BRL
    "BR" => "brl",
    # ZAR
    "ZA" => "zar",
    # CHF
    "CH" => "chf", "LI" => "chf",
    # ILS
    "IL" => "ils",
    # PHP
    "PH" => "php",
    # KRW
    "KR" => "krw",
    # PLN
    "PL" => "pln",
    # CZK
    "CZ" => "czk",
  }.freeze

  # Apple-style rounding tiers — snap converted prices to psychologically
  # appealing price points.  Each tier lists the rounding increment (in minor
  # units) to use for prices up to that threshold.
  #
  # Example for a "decimal" currency (USD/EUR/GBP/…):
  #   $0.01–$0.99   →  round to nearest $0.49 / $0.99
  #   $1.00–$9.99   →  round to nearest $0.99
  #   $10–$49.99    →  round to nearest $0.99
  #   $50–$99.99    →  round to nearest $0.99
  #   $100–$499.99  →  round to nearest $4.99
  #   $500+         →  round to nearest $9.99
  DECIMAL_TIERS = [
    [99,     99],     # under $1: snap to $0.49 or $0.99
    [999,    99],     # $1–$9.99: snap to $X.99
    [4999,   99],     # $10–$49.99: snap to $XX.99
    [9999,   99],     # $50–$99.99: snap to $XX.99
    [49999,  500],    # $100–$499: snap to nearest $5, then -1 → $X4.99 / $X9.99
    [nil,    1000],   # $500+: snap to nearest $10, then -1 → $XX9.99
  ].freeze

  # For zero-decimal (single-unit) currencies like JPY and KRW, the rounding
  # is done in whole units.
  JPY_TIERS = [
    [100,    10],      # ¥1–¥100: round to nearest ¥10
    [500,    50],      # ¥100–¥500: round to nearest ¥50
    [1000,   100],     # ¥500–¥1000: nearest ¥100
    [5000,   500],     # ¥1k–¥5k: nearest ¥500
    [10000,  1000],    # ¥5k–¥10k: nearest ¥1000
    [nil,    1000],    # ¥10k+: nearest ¥1000
  ].freeze

  KRW_TIERS = [
    [1000,   100],     # ₩1–₩1000: nearest ₩100
    [5000,   500],     # ₩1k–₩5k: nearest ₩500
    [10000,  1000],    # ₩5k–₩10k: nearest ₩1000
    [50000,  5000],    # ₩10k–₩50k: nearest ₩5000
    [100000, 10000],   # ₩50k–₩100k: nearest ₩10000
    [nil,    10000],   # ₩100k+: nearest ₩10000
  ].freeze

  # Detect the buyer's preferred currency from their IP address.
  # Returns a supported currency code string or nil if we can't determine one
  # (in which case the caller should fall back to the seller's currency).
  def self.detect_currency(ip)
    return nil if ip.blank?

    geo = GeoIp.lookup(ip)
    return nil if geo.nil? || geo.country_code.blank?

    COUNTRY_TO_CURRENCY[geo.country_code.upcase]
  end

  # Get the raw exchange rate between two currencies (without rounding).
  # Used by the frontend to dynamically convert PWYW/variant-adjusted prices.
  def self.exchange_rate(from_currency:, to_currency:)
    from_currency = from_currency.to_s.downcase
    to_currency = to_currency.to_s.downcase
    return 1.0 if from_currency == to_currency

    service = new
    # Convert 10000 base units through the same path as convert_price to get the rate
    base = 10_000
    usd_cents = service.get_usd_cents(from_currency, base)
    target_cents = service.usd_cents_to_currency(to_currency, usd_cents)
    (target_cents.to_f / base).round(6)
  end

  # Convert a price from one currency to another with Apple-style smart rounding.
  #
  # @param amount_cents [Integer] price in source currency minor units
  # @param from_currency [String] source currency code (e.g. "usd")
  # @param to_currency [String] target currency code (e.g. "eur")
  # @return [Integer] rounded price in target currency minor units
  def self.convert_price(amount_cents, from_currency:, to_currency:)
    from_currency = from_currency.to_s.downcase
    to_currency = to_currency.to_s.downcase
    return amount_cents if from_currency == to_currency
    return 0 if amount_cents == 0

    service = new
    # Convert to USD first (our common base), then to target currency.
    usd_cents = service.get_usd_cents(from_currency, amount_cents)
    raw_target_cents = service.usd_cents_to_currency(to_currency, usd_cents)

    smart_round(raw_target_cents, to_currency)
  end

  # Apple-style smart rounding: snap a raw converted price to the nearest
  # psychologically appealing price point.
  def self.smart_round(amount_cents, currency)
    return 0 if amount_cents <= 0

    currency = currency.to_s.downcase
    single_unit = new.is_currency_type_single_unit?(currency)

    tiers = case currency
            when "jpy" then JPY_TIERS
            when "krw" then KRW_TIERS
            else
              if single_unit
                JPY_TIERS # fallback for any future single-unit currencies
              else
                DECIMAL_TIERS
              end
            end

    is_zero_decimal = %w[jpy krw].include?(currency) || single_unit

    increment = tiers.find { |threshold, _| threshold.nil? || amount_cents <= threshold }&.last || tiers.last.last

    if !is_zero_decimal && increment == 99
      # For .99 rounding: round up to next dollar, then subtract 1 cent
      # e.g. 1423 → round up to 1500 → 1499
      dollars = (amount_cents / 100.0).ceil
      (dollars * 100) - 1
    elsif !is_zero_decimal && (increment == 500 || increment == 1000)
      # For $5/$10 tier rounding with .99 endings:
      # Round to nearest $5 or $10, then subtract 1 cent
      # e.g. increment=500: 12300 → round to 12500 → 12499 ($124.99)
      # e.g. increment=1000: 52300 → round to 52000 → 51999 ($519.99)
      rounded = ((amount_cents.to_f / increment).round * increment).to_i
      rounded - 1
    else
      # Standard rounding: round to nearest increment
      ((amount_cents.to_f / increment).round * increment).to_i
    end
  end
end
