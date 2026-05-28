# frozen_string_literal: true

require_relative "test_helper"

# Two-Factor Authentication flow.
#
# Coverage philosophy: we exercise the user-facing 2FA challenge gate. The
# pure-Rails behavior (token validity, sign-in side effects) is best covered
# at the request level - see follow-ups. Three browser-level behaviors that
# only make sense in a system test:
#   1. A 2FA-enabled login bounces to /two-factor instead of completing.
#   2. Submitting a wrong token keeps the user on /two-factor.
#   3. Resending the token keeps the user on /two-factor (no 500, no
#      redirect-away).
#
# Out of scope here:
#   - Correct-token-completes-login: the Inertia form auto-submits on the
#     6th digit via React state, which races Playwright's input synthesis;
#     the underlying controller path is straight Rails and is owned by
#     request specs (TwoFactorAuthenticationController#create).
#   - TOTP/authenticator-app flow - needs Feature.activate_user(:authenticator_2fa)
#     + a confirmed totp_credential. Covered by request specs.
#   - Recovery code redemption - same setup dependency.
#   - 2FA cookie remembering across logins - needs cookie-jar inspection,
#     better unit-tested at the validator level.
#   - Mailer wiring for the emailed token - TwoFactorAuthenticationMailer
#     is request/mailer-spec material.
class TwoFactorAuthenticationTest < SystemTests::SystemTestCase
  PASSWORD = "test-password-123!"

  def test_login_for_2fa_user_redirects_to_two_factor_challenge
    submit_login(users(:two_factor_user).email, PASSWORD)
    assert_match %r{/two-factor\b}, page.url,
                 "expected 2FA-enabled login to be challenged at /two-factor, got #{page.url}"
  end

  def test_wrong_token_keeps_user_on_two_factor
    submit_login(users(:two_factor_user).email, PASSWORD)
    assert_match %r{/two-factor\b}, page.url

    page.fill('input[autocomplete="one-time-code"]', "999999")
    # On invalid token the controller 303s back to /two-factor with a
    # warning flash + ?user_id= query param. Wait for that param to confirm
    # the round-trip happened (the path stays /two-factor either way, so
    # the query param is the observable signal of a completed POST).
    page.wait_for_url(%r{/two-factor\?user_id=})

    assert_match %r{/two-factor\b}, page.url,
                 "expected wrong token to leave us on /two-factor, got #{page.url}"
  end

  def test_resend_token_button_stays_on_two_factor
    submit_login(users(:two_factor_user).email, PASSWORD)
    assert_match %r{/two-factor\b}, page.url

    # Resend posts to /two-factor/resend_authentication_token and 303s back
    # to /two-factor with a flash notice. We assert the round-trip works
    # without 500 / blank page / redirect away.
    page.get_by_role("button", name: /resend/i).click
    page.wait_for_load_state(state: "networkidle")

    assert_match %r{/two-factor\b}, page.url,
                 "expected resend to land back on /two-factor, got #{page.url}"
  end

  private

  def submit_login(email, password)
    page.goto(url_for("/login"))
    page.fill('input[type="email"]', email)
    page.fill('input[type="password"]', password)
    page.click('button[type="submit"]')
    page.wait_for_load_state(state: "networkidle")
  end
end
