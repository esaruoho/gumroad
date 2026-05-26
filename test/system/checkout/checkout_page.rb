# frozen_string_literal: true

# CheckoutPage — page object for the React checkout flow.
#
# Wraps the raw Playwright API in semantic methods so tests can say:
#
#   page = CheckoutPage.new(@page).goto_product(products(:digital_ebook))
#   page.add_to_cart.fill_email("buyer@example.com").fill_card(StripeTestCards::VISA_SUCCESS)
#   page.submit.wait_for_receipt
#
# Selectors target stable React component contracts (data-helper attrs, role-based locators)
# rather than CSS classes that churn on React re-renders.
#
# Subclass for variant flows:
#   - BundleCheckoutPage (multi-product carts)
#   - SubscriptionCheckoutPage (recurring billing flows)
#   - TippingCheckoutPage (pay-what-you-want)
class CheckoutPage
  attr_reader :page

  def initialize(playwright_page)
    @page = playwright_page
  end

  # ---------- Navigation ----------
  def goto_product(product, params: {})
    qs = params.empty? ? "" : "?" + params.to_query
    @page.goto("/l/#{product.unique_permalink}#{qs}")
    @page.wait_for_load_state(state: "networkidle")
    self
  end

  def add_to_cart
    @page.click('button:has-text("I want this")')
    @page.wait_for_load_state(state: "networkidle")
    self
  end

  # ---------- Form fields ----------
  def fill_email(email)
    @page.fill('input[type="email"]', email)
    self
  end

  def fill_card(card_number, exp_month: "12", exp_year: "34", cvc: "123")
    # Stripe Elements iframe — switch into it before filling.
    frame = @page.frame_locator('iframe[name^="__privateStripeFrame"]').first
    frame.locator('input[name="cardnumber"]').fill(card_number)
    frame.locator('input[name="exp-date"]').fill("#{exp_month}/#{exp_year}")
    frame.locator('input[name="cvc"]').fill(cvc)
    self
  end

  def fill_billing_country(country_code)
    @page.select_option('select[name="country"]', country_code)
    self
  end

  def fill_zip(zip)
    @page.fill('input[name="zip_code"]', zip)
    self
  end

  # ---------- 3DS / SCA ----------
  def complete_3ds_challenge
    frame = @page.frame_locator('iframe[name^="__privateStripeFrame"][src*="acs"]').first
    frame.locator('button:has-text("Complete authentication")').click
    self
  end

  def abandon_3ds_challenge
    frame = @page.frame_locator('iframe[name^="__privateStripeFrame"][src*="acs"]').first
    frame.locator('button:has-text("Fail authentication")').click
    self
  end

  # ---------- Submission ----------
  def submit
    @page.click('button:has-text("Pay")')
    self
  end

  def wait_for_receipt
    @page.wait_for_url(%r{/library|/receipt|/d/\w+}, timeout: 30_000)
    self
  end

  # ---------- Assertions (predicate methods, test calls assert_predicate) ----------
  def has_receipt?
    @page.url.match?(%r{/library|/receipt|/d/\w+})
  end

  def has_decline_message?(text = nil)
    locator = @page.get_by_role("alert")
    return false unless locator.count > 0
    text ? locator.text_content.include?(text) : true
  end

  def has_3ds_challenge?
    @page.locator('iframe[name^="__privateStripeFrame"][src*="acs"]').count > 0
  end

  # ---------- Currency display ----------
  def displayed_total_text
    @page.locator('[data-helper="cart-total"]').text_content
  end
end
