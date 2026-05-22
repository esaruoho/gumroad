# frozen_string_literal: true

require_relative "test_helper"

# Password reset request flow.
#
# Coverage philosophy: assert the user-visible navigation contract of the
# reset-request half of the flow. URL transitions are the success oracle.
# Two behaviors:
#   1. Requesting a reset for an existing account redirects to /login.
#   2. Requesting for an unknown email keeps you on the forgot-password form
#      (controller falls into redirect_back with a warning flash).
#
# Out of scope here:
#   - The /users/forgot_password/edit submit → root_path → signed-in flow.
#     The Edit page is a React component (PasswordInput from
#     `$app/components/PasswordInput`) that wraps a native input with its
#     own state; reliably driving it through Playwright requires component-
#     aware selectors. Better covered at the request level —
#     User::PasswordsController#update is straight Rails and a request spec
#     gives full assertion coverage (password actually changed, session
#     signed in, 2FA bridge respected) without the React indirection.
#   - Email delivery / template rendering — mailer specs cover that.
#   - Token expiry semantics — Devise-internal, unit-tested.
#   - Pwned password warnings on new password — Pwned wrapper, unit-tested.
class PasswordResetTest < SystemTests::SystemTestCase
  def test_request_reset_for_existing_user_redirects_to_login
    user = users(:reset_user)

    page.goto(url_for("/users/forgot_password/new"))
    page.fill('input[type="email"]', user.email)
    page.click('button[type="submit"]')
    page.wait_for_load_state(state: "networkidle")

    # Devise's PasswordsController#create redirects to login_url with a
    # "Password reset sent!" flash on success. The redirect IS the contract;
    # the flash notice itself is rendered by a toast component on the next
    # page paint and is incidental to the auth invariant.
    assert_match %r{/login\b}, page.url,
                 "expected reset request to redirect to /login, got #{page.url}"
  end

  def test_request_reset_for_unknown_email_stays_on_forgot_password
    page.goto(url_for("/users/forgot_password/new"))
    page.fill('input[type="email"]', "ghost-#{SecureRandom.hex(4)}@example.com")
    page.click('button[type="submit"]')
    page.wait_for_load_state(state: "networkidle")

    # PasswordsController#create falls into redirect_back with a warning when
    # no live user matches. The forgot-password page is the natural fallback,
    # and crucially we do NOT leak account existence by redirecting to /login.
    assert_match %r{/users/forgot_password\b}, page.url,
                 "expected unknown-email reset to stay on forgot_password, got #{page.url}"
    refute_match %r{/login\b}, page.url,
                 "unknown-email reset must NOT redirect to /login (would leak account existence)"
  end
end
