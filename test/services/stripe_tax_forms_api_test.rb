# frozen_string_literal: true

require "test_helper"

class StripeTaxFormsApiTest < ActiveSupport::TestCase
  setup do
    @stripe_account_id = "acct_1234567890"
    @form_type = "us_1099_k"
    @year = 2024
    Rails.cache.delete("stripe_tax_forms_#{@form_type}_#{@stripe_account_id}")
  end

  test "#tax_forms_by_year returns tax forms grouped by year" do
    with_stripe_tax_forms do
      result = service.tax_forms_by_year

      assert_equal [2024, 2023, 2022, 2021, 2020], result.keys

      tax_form_2024 = result[2024]
      assert_equal "taxform_1c", tax_form_2024.id
      assert_equal "tax.form", tax_form_2024.object
      assert_equal "us_1099_k", tax_form_2024.type
      assert_equal true, tax_form_2024.livemode
      assert_equal "acct_1234567890", tax_form_2024.payee.account
      assert_equal 2024, tax_form_2024.us_1099_k.reporting_year
    end
  end

  test "#tax_forms_by_year raises error for invalid form type" do
    invalid_service = StripeTaxFormsApi.new(stripe_account_id: @stripe_account_id, form_type: "invalid_type", year: @year)

    error = assert_raises(RuntimeError) { invalid_service.tax_forms_by_year }

    assert_equal "Invalid tax form type: invalid_type", error.message
  end

  test "#tax_forms_by_year returns empty hash on Stripe API error" do
    notify_calls = []
    stripe_error = Stripe::APIConnectionError.new("Connection failed")

    ErrorNotifier.stub(:notify, ->(error) { notify_calls << error }) do
      Stripe.stub(:raw_request, ->(*_args) { raise stripe_error }) do
        assert_equal({}, service.tax_forms_by_year)
      end
    end

    assert_equal [stripe_error], notify_calls
  end

  test "#download_tax_form downloads the tax form PDF for the specified year" do
    http_calls = []

    with_stripe_tax_forms do
      HTTParty.stub(:get, ->(url, **kwargs, &block) {
        http_calls << [url, kwargs]
        block.call("PDF content")
      }) do
        result = service.download_tax_form

        assert_instance_of Tempfile, result
        assert_includes result.path, "tax_form_us_1099_k_2024_acct_1234567890"
        assert_equal ".pdf", File.extname(result.path)
        assert_equal "PDF content", result.read
        result.close
        result.unlink
      end
    end

    assert_equal "https://files.stripe.com/v1/tax/forms/taxform_1c/pdf", http_calls.first.first
    assert_match(/Bearer/, http_calls.first.last.dig(:headers, "Authorization"))
  end

  test "#download_tax_form returns nil when tax form is not found for the year" do
    service_2019 = StripeTaxFormsApi.new(stripe_account_id: @stripe_account_id, form_type: @form_type, year: 2019)

    with_stripe_tax_forms do
      assert_nil service_2019.download_tax_form
    end
  end

  test "#download_tax_form returns nil when there is an error" do
    notify_calls = []
    http_error = HTTParty::Error.new("Connection failed")

    with_stripe_tax_forms do
      ErrorNotifier.stub(:notify, ->(error) { notify_calls << error }) do
        HTTParty.stub(:get, ->(*_args, **_kwargs, &_block) { raise http_error }) do
          assert_nil service.download_tax_form
        end
      end
    end

    assert_equal [http_error], notify_calls
  end

  private
    class FakeStripeList
      def initialize(forms)
        @forms = forms
      end

      def auto_paging_each(&block)
        @forms.each(&block)
      end
    end

    def service
      StripeTaxFormsApi.new(stripe_account_id: @stripe_account_id, form_type: @form_type, year: @year)
    end

    def with_stripe_tax_forms(&block)
      response = Struct.new(:http_body).new("stripe-response")
      forms = FakeStripeList.new((2024).downto(2020).map { |year| stripe_tax_form(year) })

      Stripe.stub(:raw_request, ->(*_args) { response }) do
        Stripe.stub(:deserialize, ->(body) {
          assert_equal "stripe-response", body
          forms
        }, &block)
      end
    end

    def stripe_tax_form(year)
      Stripe::StripeObject.construct_from(
        id: "taxform_#{year == 2024 ? '1c' : year}",
        object: "tax.form",
        type: "us_1099_k",
        livemode: true,
        payee: { account: @stripe_account_id },
        us_1099_k: { reporting_year: year },
      )
    end
end
