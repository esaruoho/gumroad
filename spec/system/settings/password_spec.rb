# frozen_string_literal: true

require "spec_helper"

# Native Playwright version of spec/requests/settings/password_spec.rb
#
# Uses playwright-ruby-client directly instead of Capybara DSL.
# Benefits:
# - Native auto-waiting (no sleep/retry)
# - get_by_label, get_by_role selectors
# - No stale element errors
# - Cleaner, more readable test code
describe("Password Settings", driver: :playwright) do
  let(:compromised_password) { "password" }
  let(:not_compromised_password) { SecureRandom.hex(24) }

  def page
    @playwright_page
  end

  def login_via_browser(user)
    page.goto("/login")
    page.get_by_label("Email").fill(user.email)
    page.locator("input[type='password']").fill(user.password)
    page.get_by_role("button", name: "Login").click
    # Wait for successful login — we should land on a page with the main nav
    page.locator("nav[aria-label='Main']").wait_for(state: "visible", timeout: 15_000)
  end

  def alert_text
    page.locator("[role='alert']").text_content
  end

  def expect_alert(text:)
    expect(page.locator("[role='alert']")).to have_text(text)
  end

  context "when logged in using social login provider" do
    let(:user) { create(:user, provider: :facebook, password: "-42Q_.c_3628Ca!mW-xTJ8v*") }

    it "doesn't allow setting a new password with a value that was found in the password breaches" do
      login_via_browser(user)
      page.goto("/settings/password")

      # Social login users don't see "Old password"
      expect(page.get_by_label("Old password").count).to eq(0)

      page.get_by_label("Add password").fill(compromised_password)

      vcr_turned_on do
        VCR.use_cassette("Add Password-with a compromised password") do
          with_real_pwned_password_check do
            page.get_by_role("button", name: "Change password").click
            expect_alert(
              text: "New password has previously appeared in a data breach as per haveibeenpwned.com and should never be used. Please choose something harder to guess.",
            )
          end
        end
      end
    end

    it "allows setting a new password with a value that was not found in the password breaches" do
      login_via_browser(user)
      page.goto("/settings/password")

      expect(page.get_by_label("Old password").count).to eq(0)

      page.get_by_label("Add password").fill(not_compromised_password)

      vcr_turned_on do
        VCR.use_cassette("Add Password-with a not compromised password") do
          with_real_pwned_password_check do
            page.get_by_role("button", name: "Change password").click
            expect_alert(text: "You have successfully changed your password.")
          end
        end
      end
    end
  end

  context "when not logged in using social provider" do
    let(:user) { create(:user) }

    it "validates the new password length" do
      login_via_browser(user)
      page.goto("/settings/password")

      # Too short
      page.get_by_label("Old password").fill(user.password)
      page.get_by_label("New password").fill("123")
      encrypted_before = user.reload.encrypted_password
      page.get_by_role("button", name: "Change password").click
      expect_alert(text: "Your new password is too short.")
      expect(user.reload.encrypted_password).to eq(encrypted_before)

      # Minimum length (4 chars)
      page.get_by_label("New password").fill("1234")
      page.get_by_role("button", name: "Change password").click
      expect_alert(text: "You have successfully changed your password.")
      expect(user.reload.encrypted_password).not_to eq(encrypted_before)

      # Too long (128 chars)
      encrypted_before = user.reload.encrypted_password
      page.get_by_label("Old password").fill("1234")
      page.get_by_label("New password").fill("*" * 128)
      page.get_by_role("button", name: "Change password").click
      expect_alert(text: "Your new password is too long.")
      expect(user.reload.encrypted_password).to eq(encrypted_before)

      # Max length (127 chars)
      page.get_by_label("Old password").fill("1234")
      page.get_by_label("New password").fill("*" * 127)
      page.get_by_role("button", name: "Change password").click
      expect_alert(text: "You have successfully changed your password.")
      expect(user.reload.encrypted_password).not_to eq(encrypted_before)
    end

    it "doesn't allow changing the password with a value that was found in the password breaches" do
      login_via_browser(user)
      page.goto("/settings/password")

      page.get_by_label("Old password").fill(user.password)
      page.get_by_label("New password").fill(compromised_password)

      vcr_turned_on do
        VCR.use_cassette("Add Password-with a compromised password") do
          with_real_pwned_password_check do
            page.get_by_role("button", name: "Change password").click
            expect_alert(
              text: "New password has previously appeared in a data breach as per haveibeenpwned.com and should never be used. Please choose something harder to guess.",
            )
          end
        end
      end
    end

    it "allows changing the password with a value that was not found in the password breaches" do
      login_via_browser(user)
      page.goto("/settings/password")

      page.get_by_label("Old password").fill(user.password)
      page.get_by_label("New password").fill(not_compromised_password)

      vcr_turned_on do
        VCR.use_cassette("Add Password-with a not compromised password") do
          with_real_pwned_password_check do
            page.get_by_role("button", name: "Change password").click
            expect_alert(text: "You have successfully changed your password.")
          end
        end
      end
    end
  end

  describe "two-factor authentication section" do
    let(:user) { create(:user) }

    context "when feature flag is active" do
      before do
        Feature.activate(:authenticator_2fa)
      end

      it "displays authenticator app status" do
        login_via_browser(user)
        page.goto("/settings/password")

        expect(page.get_by_text("Two-factor authentication")).to be_visible
        expect(page.get_by_text("Authenticator app")).to be_visible
        expect(page.get_by_role("button", name: "Set up")).to be_visible
      end

      it "allows setting up and then removing the authenticator app" do
        login_via_browser(user)
        page.goto("/settings/password")

        page.get_by_role("button", name: "Set up").click
        expect(page.get_by_text("Scan this QR code")).to be_visible
        expect(page.locator("[data-testid='qr-code']")).to be_visible

        credential = user.reload.totp_credential
        expect(credential).to be_present
        expect(credential).not_to be_confirmed

        page.get_by_label("Enter the code from your authenticator app").fill(credential.otp_code)
        page.get_by_role("button", name: "Verify").click

        expect(page.get_by_text("Save these codes")).to be_visible
        expect(credential.reload).to be_confirmed

        page.get_by_role("button", name: "Done").click
        expect(page.get_by_role("button", name: "Remove")).to be_visible

        page.get_by_role("button", name: "Remove").click
        expect(page.get_by_role("button", name: "Set up")).to be_visible
        expect(user.reload.totp_credential).to be_nil
      end

      context "when authenticator app is enabled" do
        before do
          create(:totp_credential, :with_recovery_codes, user:)
        end

        it "allows regenerating recovery codes" do
          login_via_browser(user)
          page.goto("/settings/password")

          page.get_by_role("button", name: "Regenerate recovery codes").click

          expect(page.get_by_text("Save these codes")).to be_visible
          expect(page.get_by_role("button", name: "Copy all")).to be_visible
          expect(page.get_by_role("button", name: "Download")).to be_visible

          page.get_by_role("button", name: "Done").click
          expect(page.get_by_text("Save these codes")).not_to be_visible
        end
      end
    end

    context "when feature flag is not active" do
      it "does not display the two-factor authentication section" do
        login_via_browser(user)
        page.goto("/settings/password")

        expect(page.get_by_text("Two-factor authentication").count).to eq(0)
        expect(page.get_by_text("Authenticator app").count).to eq(0)
      end
    end
  end
end
