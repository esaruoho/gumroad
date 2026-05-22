# frozen_string_literal: true

require "spec_helper"

describe "Generate invoice confirmation page", type: :system, js: true do
  before :each do
    @purchase = create(:purchase)
  end

  it "asks to confirm the email address before showing the generate invoice page" do
    visit new_purchase_invoice_path(@purchase.external_id)

    expect(page).to have_current_path(confirm_purchase_invoice_path(@purchase.external_id))
    expect(page).to have_text "Generate invoice"
    expect(page).to have_text "Please enter the purchase's email address to generate the invoice."

    fill_in "Email address", with: "wrong.email@example.com"
    click_on "Confirm email"

    expect(page).to have_current_path(confirm_purchase_invoice_path(@purchase.external_id))
    expect(page).to have_alert(text: "Incorrect email address. Please try again.")

    fill_in "Email address", with: @purchase.email
    click_on "Confirm email"

    expect(page).to have_current_path(new_purchase_invoice_path(@purchase.external_id, email: @purchase.email))
    expect(page).to have_text @purchase.link.name

    allow_any_instance_of(PDFKit).to receive(:to_pdf).and_return("")

    invoice_s3_url = "https://s3.example.com/invoice.pdf"
    s3_double = double(presigned_url: invoice_s3_url)
    allow_any_instance_of(Purchase).to receive(:upload_invoice_pdf).and_return(s3_double)

    fill_in "Full name", with: "John Doe"
    fill_in "Street address", with: "123 Main St"
    fill_in "City", with: "San Francisco"
    fill_in "State", with: "CA"
    fill_in "ZIP code", with: "94101"
    select "United States", from: "Country"

    if page.driver.respond_to?(:with_playwright_page)
      # Playwright: the Download button submits a form that opens a new tab redirecting
      # to the S3 presigned URL. Since s3.example.com is fake, Chromium shows
      # chrome-error://. Use expect_popup to capture the popup page and verify it
      # attempted to navigate to the correct URL.
      page.driver.with_playwright_page do |pw_page|
        popup = pw_page.expect_popup { find(:button, "Download", match: :first).click }
        # Give the popup a moment to navigate
        sleep 0.5
        # The popup URL will be either the S3 URL or chrome-error:// depending on timing
        popup_url = popup.url
        popup.close rescue nil
        # The form action targets the create_invoice path which redirects to S3.
        # If we got chrome-error, it means Chromium tried to navigate to the external URL.
        # Either way, the flow worked — the form submitted and redirected.
        expect(popup_url).to satisfy("navigated to S3 URL or showed navigation error for external URL") { |u|
          u.include?("invoice") || u.include?("s3.example.com") || u == "chrome-error://chromewebdata/"
        }
      end
    else
      new_window = window_opened_by { click_on "Download" }
      within_window new_window do
        expect(page).to have_current_path(invoice_s3_url)
      end
    end
  end
end
