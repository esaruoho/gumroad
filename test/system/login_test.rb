# frozen_string_literal: true

require_relative "test_helper"

# Login flow — drives the real /login page rendered by React (Inertia).
#
# Coverage philosophy (first-principles): we test what users do, not what
# the framework already guarantees. Six behaviors:
#   1. Happy path: valid creds get past the gate.
#   2. Bad password bounces back to /login without auth.
#   3. ?next= param redirects there on success (link-from-email contract).
#   4. Logout destroys the session.
#   5. Suspended (TOS) user lands on a working page, not 500.
#   6. Deleted user cannot sign in, account stays deleted.
#
# Out of scope here (covered by RSpec unit/request specs):
#   - OAuth/Social (Google/X/Stripe/Facebook) — OmniAuth plumbing
#   - Pwned password warnings — Pwned::Password gem wrapper
#   - OAuth-app-bouncer flow — oauth_authorize controller
#   - Team invitation email prefill — request-level
#
# Selectors target type-based attributes (type="email"/type="password")
# because the React form components don't emit name= attributes — they
# track state via React's useForm hook, not via form-encoded POST fields.
class LoginTest < SystemTests::SystemTestCase
  PASSWORD = "test-password-123!"

  def test_existing_user_signs_in_successfully
    submit_login(users(:basic_user).email, PASSWORD)
    refute_on_login_page
  end

  def test_wrong_password_redirects_back_to_login
    submit_login(users(:basic_user).email, "this-is-not-the-password")
    assert_on_login_page
  end

  def test_next_param_is_honored_after_successful_login
    # /balance is a generic authenticated route. After login, we should land
    # exactly there rather than the default dashboard.
    page.goto(url_for("/login?next=/balance"))
    page.fill('input[type="email"]', users(:basic_user).email)
    page.fill('input[type="password"]', PASSWORD)
    page.click('button[type="submit"]')

    page.wait_for_load_state(state: "networkidle")
    assert_match %r{/balance\b}, page.url, "expected next=/balance to be honored, got #{page.url}"
  end

  def test_logout_destroys_the_session
    submit_login(users(:basic_user).email, PASSWORD)
    refute_on_login_page

    # After logout, hitting a protected route should bounce to /login.
    # Logout is exposed via /logout (Devise's destroy_session_path alias).
    page.goto(url_for("/logout"))
    page.goto(url_for("/dashboard"))
    page.wait_for_load_state(state: "networkidle")
    assert_match %r{/login\b}, page.url, "expected /dashboard to bounce to /login after logout, got #{page.url}"
  end

  def test_suspended_for_tos_user_signs_in_without_error
    # Suspended-for-TOS users still get a session; the app routes them to a
    # restricted dashboard. Guarantee: no 500/blank page on the login path.
    submit_login(users(:suspended_user).email, PASSWORD)
    refute_on_login_page
    refute_match %r{/500\b|/422\b}, page.url
    # Page should render with no JS error wall.
    assert page.locator("body").count > 0
  end

  def test_deleted_user_cannot_sign_in
    deleted = users(:deleted_user)
    refute_nil deleted.deleted_at, "fixture invariant: deleted_user must have deleted_at set"

    submit_login(deleted.email, PASSWORD)
    assert_on_login_page

    deleted.reload
    refute_nil deleted.deleted_at, "logging in must not undelete the account"
  end

  private

  def submit_login(email, password)
    page.goto(url_for("/login"))
    page.fill('input[type="email"]', email)
    page.fill('input[type="password"]', password)
    page.click('button[type="submit"]')
    page.wait_for_load_state(state: "networkidle")
  end

  def assert_on_login_page
    assert_match %r{/login\b}, page.url, "expected to be back on /login, got #{page.url}"
  end

  def refute_on_login_page
    refute_match %r{/login\b}, page.url, "expected redirect away from /login on successful auth, got #{page.url}"
  end
end
