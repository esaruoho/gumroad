# frozen_string_literal: true

require "test_helper"

class VatValidationServiceTest < ActiveSupport::TestCase
  # Override Valvat instance behavior per test by defining a method on a
  # singleton-class hook. Easiest: stub via Valvat.new returning a Minitest::Mock
  # or a struct.
  class FakeValvat
    attr_accessor :vat_country_code, :exists_proc, :valid_proc
    def initialize(country:, exists_proc: ->(**_) { true }, valid_proc: -> { true })
      @vat_country_code = country
      @exists_proc = exists_proc
      @valid_proc = valid_proc
    end
    def exists?(**kw) = @exists_proc.call(**kw)
    def valid? = @valid_proc.call
  end

  def stub_valvat(fake)
    Valvat.stub :new, ->(_) { fake } do
      yield
    end
  end

  test "returns false when provided vat is nil" do
    assert_equal false, VatValidationService.new(nil).process
  end

  test "returns false when invalid vat is provided" do
    fake = FakeValvat.new(country: nil, exists_proc: ->(**_) { false }, valid_proc: -> { false })
    stub_valvat(fake) { assert_equal false, VatValidationService.new("xxx").process }
  end

  test "returns true when valid vat is provided" do
    fake = FakeValvat.new(country: "IE", exists_proc: ->(**_) { { "valid" => true, "name" => "Co" } })
    stub_valvat(fake) { assert_equal true, VatValidationService.new("IE6388047V").process }
  end

  test "works well with GB numbers" do
    fake = FakeValvat.new(country: "GB", valid_proc: -> { true })
    stub_valvat(fake) { assert_equal true, VatValidationService.new("GB902194939").process }
  end

  test "falls back to local vat validation when VIES hits timeout/rate limits" do
    called = false
    fake = FakeValvat.new(
      country: "IE",
      exists_proc: ->(**_) { raise Valvat::RateLimitError },
      valid_proc: -> { called = true; true }
    )
    stub_valvat(fake) { VatValidationService.new("IE6388047V").process }
    assert called
  end

  test "passes a 30-second timeout to the VIES lookup and falls back on Net::ReadTimeout" do
    captured = nil
    fake = FakeValvat.new(
      country: "IE",
      exists_proc: ->(**kw) { captured = kw; raise Net::ReadTimeout },
      valid_proc: -> { true }
    )
    stub_valvat(fake) { VatValidationService.new("IE6388047V").process }
    assert_equal GUMROAD_VAT_REGISTRATION_NUMBER, captured[:requester]
    assert_equal({ open_timeout: 30, read_timeout: 30 }, captured[:http])
  end
end
