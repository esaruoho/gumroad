# frozen_string_literal: true

require "test_helper"

class PostResendApiTest < ActiveSupport::TestCase
  # Sharpened skip-stub.
  # Original: spec/services/post_resend_api_spec.rb
  # Blocker: 25 FactoryBot refs; renders full email body via Premailer with seller_profile design (highlight_color/font/background_color), product_files, url_redirects, CTAs, audience_installments. Email-rendering chain not portable to fixtures-only without ProductFile S3 + view harness.
  test "TODO: migrate spec/services/post_resend_api_spec.rb" do
    skip "Fixture-hostile — see top-of-file blocker note"
  end
end
