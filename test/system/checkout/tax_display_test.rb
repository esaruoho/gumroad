# frozen_string_literal: true

require "json"

require_relative "../test_helper"
require_relative "../system_test_case"
require_relative "checkout_page"
require_relative "stripe_test_cards"

class TaxDisplayTest < SystemTests::SystemTestCase
  BASE_PRICE_CENTS = 100_00

  COUNTRY_TAX_CASES = [
    { name: "Iceland", flag_symbol: :collect_tax_is, country_code: "IS", rate: "0.24", product_type: :all_products },
    { name: "South Africa", flag_symbol: :collect_tax_za, country_code: "ZA", rate: "0.15", product_type: :all_products },
    { name: "Switzerland", flag_symbol: :collect_tax_ch, country_code: "CH", rate: "0.081", product_type: :all_products },
    { name: "United Arab Emirates", flag_symbol: :collect_tax_ae, country_code: "AE", rate: "0.05", product_type: :all_products },
    { name: "Bahrain", flag_symbol: :collect_tax_bh, country_code: "BH", rate: "0.10", product_type: :digital },
    { name: "Belarus", flag_symbol: :collect_tax_by, country_code: "BY", rate: "0.20", product_type: :digital },
    { name: "Chile", flag_symbol: :collect_tax_cl, country_code: "CL", rate: "0.19", product_type: :digital },
    { name: "Colombia", flag_symbol: :collect_tax_co, country_code: "CO", rate: "0.19", product_type: :digital },
    { name: "Costa Rica", flag_symbol: :collect_tax_cr, country_code: "CR", rate: "0.13", product_type: :digital },
    { name: "Ecuador", flag_symbol: :collect_tax_ec, country_code: "EC", rate: "0.12", product_type: :digital },
    { name: "Egypt", flag_symbol: :collect_tax_eg, country_code: "EG", rate: "0.14", product_type: :digital },
    { name: "Georgia", flag_symbol: :collect_tax_ge, country_code: "GE", rate: "0.18", product_type: :digital },
    { name: "Kazakhstan", flag_symbol: :collect_tax_kz, country_code: "KZ", rate: "0.12", product_type: :digital },
    { name: "Kenya", flag_symbol: :collect_tax_ke, country_code: "KE", rate: "0.16", product_type: :digital },
    { name: "Malaysia", flag_symbol: :collect_tax_my, country_code: "MY", rate: "0.06", product_type: :digital },
    { name: "Moldova", flag_symbol: :collect_tax_md, country_code: "MD", rate: "0.20", product_type: :digital },
    { name: "Morocco", flag_symbol: :collect_tax_ma, country_code: "MA", rate: "0.20", product_type: :digital },
    { name: "Nigeria", flag_symbol: :collect_tax_ng, country_code: "NG", rate: "0.075", product_type: :digital },
    { name: "Oman", flag_symbol: :collect_tax_om, country_code: "OM", rate: "0.05", product_type: :digital },
    { name: "Russia", flag_symbol: :collect_tax_ru, country_code: "RU", rate: "0.20", product_type: :digital },
    { name: "Saudi Arabia", flag_symbol: :collect_tax_sa, country_code: "SA", rate: "0.15", product_type: :digital },
    { name: "Serbia", flag_symbol: :collect_tax_rs, country_code: "RS", rate: "0.20", product_type: :digital },
    { name: "South Korea", flag_symbol: :collect_tax_kr, country_code: "KR", rate: "0.10", product_type: :digital },
    { name: "Tanzania", flag_symbol: :collect_tax_tz, country_code: "TZ", rate: "0.18", product_type: :digital },
    { name: "Thailand", flag_symbol: :collect_tax_th, country_code: "TH", rate: "0.07", product_type: :digital },
    { name: "Turkey", flag_symbol: :collect_tax_tr, country_code: "TR", rate: "0.20", product_type: :digital },
    { name: "Ukraine", flag_symbol: :collect_tax_ua, country_code: "UA", rate: "0.20", product_type: :digital },
    { name: "Uzbekistan", flag_symbol: :collect_tax_uz, country_code: "UZ", rate: "0.15", product_type: :digital },
    { name: "Vietnam", flag_symbol: :collect_tax_vn, country_code: "VN", rate: "0.10", product_type: :digital },
  ].freeze

  def setup
    super
    @cp = CheckoutPage.new(@page)
    @activated_features = []
  end

  def teardown
    @activated_features.each { Feature.deactivate(_1) }
    super
  end

  def test_us_sales_tax_az_zip_physical_product
    product = create_physical_product
    create_tax_rate(country: "US", state: "AZ", rate: "0.107")

    with_taxjar_rate("0.107", state: "AZ") do
      start_checkout(product)
      fill_physical_checkout(country_code: "US", state: "AZ", zip: "85144", city: "Queen Creek")
      assert_displayed_tax(country_code: "US", tax_cents: 10_70, total_cents: 110_70)
      purchase = submit_and_wait_for_purchase(product)
      assert_purchase_tax(purchase, country_code: "US", state: "AZ", postal_code: "85144", price_cents: BASE_PRICE_CENTS, tax_cents: 10_70)
    end
  end

  def test_us_sales_tax_ny_zip_physical_product
    product = create_physical_product
    create_tax_rate(country: "US", state: "NY", rate: "0.08875")

    with_taxjar_rate("0.08875", state: "NY") do
      start_checkout(product)
      fill_physical_checkout(country_code: "US", state: "NY", zip: "10001", city: "New York")
      assert_displayed_tax(country_code: "US", tax_cents: 8_88, total_cents: 108_88)
      purchase = submit_and_wait_for_purchase(product)
      assert_purchase_tax(purchase, country_code: "US", state: "NY", postal_code: "10001", price_cents: BASE_PRICE_CENTS, tax_cents: 8_88)
    end
  end

  def test_us_no_nexus_state_mt_shows_no_tax_line
    product = create_physical_product

    start_checkout(product)
    fill_physical_checkout(country_code: "US", state: "MT", zip: "59001", city: "Billings")
    wait_for_total(BASE_PRICE_CENTS)
    refute @cp.has_tax_line?("Sales tax US$")
    purchase = submit_and_wait_for_purchase(product)
    assert_purchase_tax(purchase, country_code: "US", state: "MT", postal_code: "59001", price_cents: BASE_PRICE_CENTS, tax_cents: 0)
  end

  def test_eu_buyer_de_digital_product_vat
    product = create_digital_product
    create_tax_rate(country: "DE", rate: "0.19")

    start_checkout(product)
    fill_digital_checkout(country_code: "DE")
    assert_displayed_tax(country_code: "DE", tax_cents: 19_00, total_cents: 119_00)
    purchase = submit_and_wait_for_purchase(product)
    assert_purchase_tax(purchase, country_code: "DE", price_cents: BASE_PRICE_CENTS, tax_cents: 19_00)
  end

  def test_eu_buyer_de_with_valid_vatin_reverse_charges_vat
    product = create_digital_product
    create_tax_rate(country: "DE", rate: "0.19")

    with_valid_vat_id do
      start_checkout(product)
      fill_digital_checkout(country_code: "DE")
      @cp.fill_vatin("DE123456789")
      wait_for_total(BASE_PRICE_CENTS)
      refute @cp.has_tax_line?("VAT US$")
      purchase = submit_and_wait_for_purchase(product)
      assert_purchase_tax(purchase, country_code: "DE", price_cents: BASE_PRICE_CENTS, tax_cents: 0, business_vat_id: "DE123456789")
    end
  end

  def test_uk_buyer_post_brexit_digital_product_vat
    product = create_digital_product
    create_tax_rate(country: "GB", rate: "0.20")

    start_checkout(product)
    fill_digital_checkout(country_code: "GB", card_number: StripeTestCards::UK_VISA)
    assert_displayed_tax(country_code: "GB", tax_cents: 20_00, total_cents: 120_00)
    purchase = submit_and_wait_for_purchase(product)
    assert_purchase_tax(purchase, country_code: "GB", price_cents: BASE_PRICE_CENTS, tax_cents: 20_00)
  end

  def test_india_buyer_digital_product_igst
    product = create_digital_product
    activate_feature(:collect_tax_in)
    create_tax_rate(country: "IN", rate: "0.18")

    start_checkout(product)
    fill_digital_checkout(country_code: "IN")
    assert_displayed_tax(country_code: "IN", tax_cents: 18_00, total_cents: 118_00)
    purchase = submit_and_wait_for_purchase(product)
    assert_purchase_tax(purchase, country_code: "IN", price_cents: BASE_PRICE_CENTS, tax_cents: 18_00)
  end

  def test_australia_gst
    product = create_digital_product
    create_tax_rate(country: "AU", rate: "0.10")

    start_checkout(product)
    fill_digital_checkout(country_code: "AU")
    assert_displayed_tax(country_code: "AU", tax_cents: 10_00, total_cents: 110_00)
    purchase = submit_and_wait_for_purchase(product)
    assert_purchase_tax(purchase, country_code: "AU", price_cents: BASE_PRICE_CENTS, tax_cents: 10_00)
  end

  def test_singapore_gst
    product = create_digital_product
    create_tax_rate(country: "SG", rate: "0.08", applicable_years: [Time.current.year])

    start_checkout(product)
    fill_digital_checkout(country_code: "SG")
    assert_displayed_tax(country_code: "SG", tax_cents: 8_00, total_cents: 108_00)
    purchase = submit_and_wait_for_purchase(product)
    assert_purchase_tax(purchase, country_code: "SG", price_cents: BASE_PRICE_CENTS, tax_cents: 8_00)
  end

  def test_norway_tax
    product = create_digital_product
    create_tax_rate(country: "NO", rate: "0.25")

    start_checkout(product)
    fill_digital_checkout(country_code: "NO")
    assert_displayed_tax(country_code: "NO", tax_cents: 25_00, total_cents: 125_00)
    purchase = submit_and_wait_for_purchase(product)
    assert_purchase_tax(purchase, country_code: "NO", price_cents: BASE_PRICE_CENTS, tax_cents: 25_00)
  end

  def test_japan_jct
    product = create_digital_product
    activate_feature(:collect_tax_jp)
    create_tax_rate(country: "JP", rate: "0.10")

    start_checkout(product)
    fill_digital_checkout(country_code: "JP")
    assert_displayed_tax(country_code: "JP", tax_cents: 10_00, total_cents: 110_00)
    purchase = submit_and_wait_for_purchase(product)
    assert_purchase_tax(purchase, country_code: "JP", price_cents: BASE_PRICE_CENTS, tax_cents: 10_00)
  end

  def test_new_zealand_gst
    product = create_digital_product
    activate_feature(:collect_tax_nz)
    create_tax_rate(country: "NZ", rate: "0.15")

    start_checkout(product)
    fill_digital_checkout(country_code: "NZ")
    assert_displayed_tax(country_code: "NZ", tax_cents: 15_00, total_cents: 115_00)
    purchase = submit_and_wait_for_purchase(product)
    assert_purchase_tax(purchase, country_code: "NZ", price_cents: BASE_PRICE_CENTS, tax_cents: 15_00)
  end

  def test_canada_on_gst_hst
    product = create_digital_product
    create_tax_rate(country: "CA", state: "ON", rate: "0.13")

    with_taxjar_rate("0.13", state: "ON") do
      start_checkout(product)
      fill_digital_checkout(country_code: "CA", state: "ON")
      assert_displayed_tax(country_code: "CA", tax_cents: 13_00, total_cents: 113_00)
      purchase = submit_and_wait_for_purchase(product)
      assert_purchase_tax(purchase, country_code: "CA", state: "ON", price_cents: BASE_PRICE_CENTS, tax_cents: 13_00)
    end
  end

  COUNTRY_TAX_CASES.each do |row|
    test "country tax matrix - #{row[:name]}" do
      product = create_digital_product
      activate_feature(row.fetch(:flag_symbol))
      tax_cents = tax_cents_for(BASE_PRICE_CENTS, row.fetch(:rate))
      create_tax_rate(country: row.fetch(:country_code), rate: row.fetch(:rate))

      start_checkout(product)
      fill_digital_checkout(country_code: row.fetch(:country_code))
      assert_displayed_tax(country_code: row.fetch(:country_code), tax_cents:, total_cents: BASE_PRICE_CENTS + tax_cents)
      purchase = submit_and_wait_for_purchase(product)
      assert_purchase_tax(purchase, country_code: row.fetch(:country_code), price_cents: BASE_PRICE_CENTS, tax_cents:)
    end
  end

  def test_country_change_recomputes_tax
    product = create_digital_product
    create_tax_rate(country: "DE", rate: "0.19")

    start_checkout(product)
    fill_digital_checkout(country_code: "US", zip: "59001", submit_fields: false)
    wait_for_total(BASE_PRICE_CENTS)
    refute @cp.has_tax_line?("VAT US$")

    @cp.fill_billing_country("DE")
    assert_displayed_tax(country_code: "DE", tax_cents: 19_00, total_cents: 119_00)
    fill_payment_fields
    purchase = submit_and_wait_for_purchase(product)
    assert_purchase_tax(purchase, country_code: "DE", price_cents: BASE_PRICE_CENTS, tax_cents: 19_00)
  end

  def test_variant_price_difference_recomputes_tax
    product = create_variant_product
    create_tax_rate(country: "DE", rate: "0.19")

    start_checkout(product, option_name: "Basic")
    fill_digital_checkout(country_code: "DE")
    assert_displayed_tax(country_code: "DE", tax_cents: 19_00, total_cents: 119_00)

    @page.get_by_role("button", name: "Edit").click
    @page.get_by_role("radio", name: "Pro").click
    @page.get_by_role("button", name: "Save changes").click
    assert_displayed_tax(country_code: "DE", tax_cents: 28_50, total_cents: 178_50)
    purchase = submit_and_wait_for_purchase(product)
    assert_purchase_tax(purchase, country_code: "DE", price_cents: 150_00, tax_cents: 28_50)
  end

  def test_tiered_membership_tax
    product = create_tiered_membership_product
    create_tax_rate(country: "DE", rate: "0.19")

    start_checkout(product, option_name: "First Tier")
    fill_digital_checkout(country_code: "DE")
    assert_displayed_tax(country_code: "DE", tax_cents: 57, total_cents: 3_57)
    purchase = submit_and_wait_for_purchase(product)
    assert_purchase_tax(purchase, country_code: "DE", price_cents: 3_00, tax_cents: 57)
  end

  def test_tax_inclusive_and_exclusive_checkout_copy
    de_product = create_digital_product
    create_tax_rate(country: "DE", rate: "0.19")

    start_checkout(de_product)
    fill_digital_checkout(country_code: "DE", submit_fields: false)
    assert_displayed_tax(country_code: "DE", tax_cents: 19_00, total_cents: 119_00)
    refute @cp.has_tax_line?("VAT (included)")

    @context.clear_cookies

    us_product = create_physical_product
    create_tax_rate(country: "US", state: "AZ", rate: "0.107")

    with_taxjar_rate("0.107", state: "AZ") do
      start_checkout(us_product)
      fill_physical_checkout(country_code: "US", state: "AZ", zip: "85144", city: "Queen Creek", submit_fields: false)
      assert_displayed_tax(country_code: "US", tax_cents: 10_70, total_cents: 110_70)
      refute @cp.has_tax_line?("Sales tax (included)")
    end
  end

  def test_collect_eu_vat_seller_flag_keeps_marketplace_vat_displayed
    seller = users(:basic_user)
    seller.update!(collect_eu_vat: true, is_eu_vat_exclusive: true)
    product = create_digital_product(user: seller)
    create_tax_rate(country: "ES", rate: "0.21")

    start_checkout(product)
    fill_digital_checkout(country_code: "ES")
    assert_displayed_tax(country_code: "ES", tax_cents: 21_00, total_cents: 121_00)
    purchase = submit_and_wait_for_purchase(product)
    assert_purchase_tax(purchase, country_code: "ES", price_cents: BASE_PRICE_CENTS, tax_cents: 21_00)
  end

  def test_vatin_field_appears_only_for_taxable_countries_that_accept_business_ids
    product = create_digital_product
    create_tax_rate(country: "DE", rate: "0.19")

    start_checkout(product)
    fill_digital_checkout(country_code: "US", zip: "59001", submit_fields: false)
    wait_for_total(BASE_PRICE_CENTS)
    assert_equal 0, business_id_inputs.count

    @cp.fill_billing_country("DE")
    assert_displayed_tax(country_code: "DE", tax_cents: 19_00, total_cents: 119_00)
    assert_operator business_id_inputs.count, :>, 0
  end

  private
    class TaxjarRateStub
      def initialize(rate:, state:)
        @rate = BigDecimal(rate.to_s)
        @state = state
      end

      def calculate_tax_for_order(origin:, destination:, nexus_address:, quantity:, product_tax_code:, unit_price_dollars:, shipping_dollars:)
        taxable_dollars = BigDecimal(unit_price_dollars.to_s) * quantity + BigDecimal(shipping_dollars.to_s)
        amount_to_collect = (taxable_dollars * @rate).round(2)

        {
          "rate" => @rate.to_f,
          "amount_to_collect" => amount_to_collect.to_f,
          "breakdown" => {
            "state_tax_rate" => @rate.to_f,
            "county_tax_rate" => 0,
            "city_tax_rate" => 0,
            "gst_tax_rate" => 0,
            "pst_tax_rate" => 0,
            "qst_tax_rate" => 0,
          },
          "jurisdictions" => {
            "state" => @state,
            "county" => nil,
            "city" => nil,
          },
        }
      end
    end

    class AlwaysValidVatId
      def process
        true
      end
    end

    def app_base_url
      url_for("/").delete_suffix("/")
    end

    def create_digital_product(user: users(:basic_user), price_cents: BASE_PRICE_CENTS)
      Link.create!(
        user:,
        name: "Tax Display #{SecureRandom.hex(4)}",
        description: "System tax display coverage",
        price_cents:,
      )
    end

    def create_physical_product
      product = create_digital_product
      product.update!(
        require_shipping: true,
        native_type: Link::NATIVE_TYPE_PHYSICAL,
        skus_enabled: true,
        is_physical: true,
        quantity_enabled: true,
        should_show_sales_count: true,
      )
      product.shipping_destinations.create!(
        country_code: Product::Shipping::ELSEWHERE,
        one_item_rate_cents: 0,
        multiple_items_rate_cents: 0,
      )
      product.skus.create!(price_difference_cents: 0, name: "DEFAULT_SKU", is_default_sku: true)
      product
    end

    def create_variant_product
      product = create_digital_product
      category = product.variant_categories.create!(title: "Plan")
      category.variants.create!(name: "Basic", price_difference_cents: 0)
      category.variants.create!(name: "Pro", price_difference_cents: 50_00)
      product
    end

    def create_tiered_membership_product
      product = Link.create!(
        user: users(:basic_user),
        name: "Tax Membership #{SecureRandom.hex(4)}",
        description: "System membership tax display coverage",
        price_cents: 3_00,
        is_recurring_billing: true,
        subscription_duration: BasePrice::Recurrence::MONTHLY,
        is_tiered_membership: true,
        native_type: Link::NATIVE_TYPE_MEMBERSHIP,
      )
      first_tier = product.tier_category.variants.first
      first_tier.update!(name: "First Tier")
      second_tier = product.tier_category.variants.create!(name: "Second Tier")
      first_tier.save_recurring_prices!(BasePrice::Recurrence::MONTHLY => { enabled: true, price: "3" })
      second_tier.save_recurring_prices!(BasePrice::Recurrence::MONTHLY => { enabled: true, price: "5" })
      product
    end

    def create_tax_rate(country:, rate:, state: nil, applicable_years: nil)
      attributes = {
        country:,
        state:,
        zip_code: nil,
        combined_rate: BigDecimal(rate.to_s),
        is_seller_responsible: false,
        is_epublication_rate: false,
      }
      attributes[:applicable_years] = applicable_years if applicable_years
      ZipTaxRate.create!(attributes)
    end

    def activate_feature(flag)
      Feature.activate(flag)
      @activated_features << flag
    end

    def with_taxjar_rate(rate, state:)
      TaxjarApi.stub(:new, TaxjarRateStub.new(rate:, state:)) { yield }
    end

    def with_valid_vat_id
      VatValidationService.stub(:new, AlwaysValidVatId.new) { yield }
    end

    def start_checkout(product, option_name: nil)
      @cp.goto_product(product, base_url: app_base_url)
      @page.get_by_role("radio", name: option_name).click if option_name
      @cp.add_to_cart
      @page.wait_for_url(%r{/checkout}, timeout: 30_000)
      @page.wait_for_load_state(state: "networkidle")
    end

    def fill_digital_checkout(country_code:, state: nil, zip: nil, card_number: StripeTestCards::VISA_SUCCESS, submit_fields: true)
      @cp.fill_email("buyer-#{SecureRandom.hex(4)}@example.com")
      @page.get_by_label("Full name").fill("Tax Buyer")
      @cp.fill_billing_country(country_code)
      fill_state(state) if state
      @cp.set_zip(zip) if zip
      fill_payment_fields(card_number:) if submit_fields
    end

    def fill_physical_checkout(country_code:, state:, zip:, city:, submit_fields: true)
      stub_shipping_address_verification
      @cp.fill_email("buyer-#{SecureRandom.hex(4)}@example.com")
      @page.get_by_label("Full name").fill("Tax Buyer")
      @page.get_by_label("Street address").fill("1 Main St")
      @page.get_by_label("City").fill(city)
      @cp.fill_billing_country(country_code)
      fill_state(state)
      @cp.set_zip(zip)
      fill_payment_fields if submit_fields
    end

    def fill_state(state)
      state_input = @page.get_by_label("State")
      if state_input.count > 0
        state_input.select_option(state)
      else
        @page.get_by_label("Province").select_option(state)
      end
      @page.keyboard.press("Tab")
    end

    def fill_payment_fields(card_number: StripeTestCards::VISA_SUCCESS)
      @cp.fill_card(card_number)
    end

    def stub_shipping_address_verification
      @page.route("**/shipments/verify_shipping_address") do |route|
        params = JSON.parse(route.request.post_data || "{}") rescue {}
        route.fulfill(
          status: 200,
          content_type: "application/json",
          body: {
            success: true,
            street_address: params["street_address"] || "1 Main St",
            city: params["city"] || "Phoenix",
            state: params["state"] || "AZ",
            zip_code: params["zip_code"] || "85001",
          }.to_json,
        )
      end
    end

    def assert_displayed_tax(country_code:, tax_cents:, total_cents:)
      line = "#{tax_label(country_code)} #{format_usd(tax_cents)}"
      wait_for_body_text(line)
      wait_for_total(total_cents)
      assert @cp.has_tax_line?(line), "Expected checkout to show tax line #{line.inspect}"
      assert_equal format_usd(total_cents), @cp.displayed_total_text.strip
    end

    def wait_for_total(total_cents)
      expected = format_usd(total_cents)
      wait_until("total #{expected}") { @cp.displayed_total_text.strip == expected }
    end

    def wait_for_body_text(text)
      wait_until("body text #{text.inspect}") { normalized_body_text.include?(text) }
    end

    def wait_until(description, timeout: 15)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
      until yield
        raise Minitest::Assertion, "Timed out waiting for #{description}" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
        sleep 0.1
      end
    end

    def normalized_body_text
      @page.locator("body").text_content.gsub(/\s+/, " ")
    end

    def submit_and_wait_for_purchase(product)
      previous_id = Purchase.maximum(:id) || 0
      @cp.submit

      wait_until("purchase for #{product.unique_permalink}", timeout: 30) do
        Purchase.where("id > ?", previous_id).where(link_id: product.id).exists?
      end
      Purchase.where("id > ?", previous_id).where(link_id: product.id).order(:id).last
    end

    def assert_purchase_tax(purchase, country_code:, price_cents:, tax_cents:, state: nil, postal_code: nil, business_vat_id: nil)
      assert_equal price_cents, purchase.price_cents
      assert_equal price_cents + tax_cents, purchase.total_transaction_cents
      assert_equal tax_cents, purchase.gumroad_tax_cents.to_i
      assert_equal 0, purchase.tax_cents.to_i
      assert_equal tax_cents.positive?, purchase.was_purchase_taxable?

      tax_info = purchase.purchase_sales_tax_info
      assert tax_info, "Expected purchase_sales_tax_info to be present"
      assert_equal country_code, tax_info.elected_country_code
      assert_equal country_code, tax_info.country_code if purchase.country.present?
      assert_equal state, tax_info.state_code if state
      assert_equal postal_code, tax_info.postal_code if postal_code
      assert_equal business_vat_id, tax_info.business_vat_id if business_vat_id
    end

    def tax_cents_for(price_cents, rate)
      (BigDecimal(price_cents.to_s) * BigDecimal(rate.to_s)).round.to_i
    end

    def format_usd(cents)
      dollars = cents / 100.0
      formatted = format("%.2f", dollars)
      formatted = formatted.sub(/\.00\z/, "")
      "US$#{formatted}"
    end

    def tax_label(country_code)
      case country_code
      when "US"
        "Sales tax"
      when "CA"
        "Tax"
      when "AU", "IN", "NZ", "SG"
        "GST"
      when "MY"
        "Service tax"
      when "JP"
        "CT"
      else
        "VAT"
      end
    end

    def business_id_inputs
      @page.locator("xpath=//label[starts-with(normalize-space(.), 'Business ')]/ancestor::fieldset//input")
    end
end
