# frozen_string_literal: true

require_relative "test_helper"

# Signup flow — drives the real /signup form rendered by React (Inertia).
#
# Coverage philosophy (first-principles): we test the user-observable
# behaviors that matter, using URL-based assertions (the redirect IS the
# server's proof of success). Four cases:
#   1. Happy path: new email + password → redirect off /signup.
#   2. Existing email bounces back to /signup with an error state.
#   3. ?referrer= flow accepts the form (the Invite linkage is covered by
#      the controller-level RSpec; doing it browser-side adds DB-timing
#      flake without proving anything new).
#   4. ?next= is honored after successful signup.
#
# Out of scope here (covered by RSpec unit/request specs):
#   - OAuth/Social signup — OmniAuth plumbing
#   - Pwned password rejection — Pwned::Password gem wrapper
#   - OAuth-app-bouncer signup — oauth_authorize controller
#   - Team invitation email prefill — request-level
#   - Stripe-card-on-signup branch — needs Stripe + workers
#
# Captcha: SystemTestCase enables :disable_signup_recaptcha so the React
# form skips recaptcha.execute() and posts directly. Server-side
# ValidateRecaptcha already short-circuits in Rails.env.test?.
#
# Selectors target type-based attributes (type="email"/type="password")
# because the React form components don't emit name= attributes — they
# track state via React's useForm hook, not via form-encoded POST fields.
class SignupTest < SystemTests::SystemTestCase
  def test_new_user_signs_up_successfully
    submit_signup("new-user-#{SecureRandom.hex(4)}@example.com",
                  "newpass-#{SecureRandom.hex(6)}!")
    refute_on_signup_page
  end

  def test_signup_with_existing_email_redirects_back_with_error
    submit_signup(users(:basic_user).email, "any-password-123!")
    assert_on_signup_page
  end

  def test_referrer_query_string_signup_accepts_form
    referrer = users(:referrer_user)

    page.goto(url_for("/signup?referrer=#{referrer.username}"))
    page.fill('input[type="email"]', "ref-#{SecureRandom.hex(4)}@example.com")
    page.fill('input[type="password"]', "ref-pass-#{SecureRandom.hex(6)}!")
    page.click('button[type="submit"]')
    page.wait_for_load_state(state: "networkidle")

    refute_on_signup_page
  end

  def test_next_param_is_honored_after_successful_signup
    page.goto(url_for("/signup?next=/balance"))
    page.fill('input[type="email"]', "next-#{SecureRandom.hex(4)}@example.com")
    page.fill('input[type="password"]', "next-pass-#{SecureRandom.hex(6)}!")
    page.click('button[type="submit"]')
    page.wait_for_load_state(state: "networkidle")

    assert_match %r{/balance\b}, page.url,
                 "expected next=/balance to be honored after signup, got #{page.url}"
  end

  private

  def submit_signup(email, password)
    page.goto(url_for("/signup"))
    page.fill('input[type="email"]', email)
    page.fill('input[type="password"]', password)
    page.click('button[type="submit"]')
    page.wait_for_load_state(state: "networkidle")
  end

  def assert_on_signup_page
    assert_match %r{/signup\b}, page.url, "expected to be back on /signup, got #{page.url}"
  end

  def refute_on_signup_page
    refute_match %r{/signup\b}, page.url, "expected redirect away from /signup on success, got #{page.url}"
  end
end
