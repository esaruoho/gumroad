# frozen_string_literal: true

require "test_helper"

class UpdateUserComplianceInfoTest < ActiveSupport::TestCase
  test "individual_tax_id exceeding max length returns an error without RSA encryption" do
    user = users(:compliance_test_user)
    params = ActionController::Parameters.new(individual_tax_id: "1" * 201)
    result = UpdateUserComplianceInfo.new(compliance_params: params, user: user).process
    assert_equal false, result[:success]
    assert_equal "Individual tax id is too long", result[:error_message]
  end

  test "business_tax_id exceeding max length returns an error without RSA encryption" do
    user = users(:compliance_test_user)
    params = ActionController::Parameters.new(business_tax_id: "1" * 201)
    result = UpdateUserComplianceInfo.new(compliance_params: params, user: user).process
    assert_equal false, result[:success]
    assert_equal "Business tax id is too long", result[:error_message]
  end

  test "ssn_last_four exceeding max length returns an error without RSA encryption" do
    user = users(:compliance_test_user)
    params = ActionController::Parameters.new(ssn_last_four: "1" * 201)
    result = UpdateUserComplianceInfo.new(compliance_params: params, user: user).process
    assert_equal false, result[:success]
    assert_equal "Individual tax id is too long", result[:error_message]
  end

  test "valid individual_tax_id but oversized ssn_last_four errors before assigning either" do
    user = users(:compliance_test_user)
    params = ActionController::Parameters.new(individual_tax_id: "123456789", ssn_last_four: "1" * 201)
    result = UpdateUserComplianceInfo.new(compliance_params: params, user: user).process
    assert_equal false, result[:success]
    assert_equal "Individual tax id is too long", result[:error_message]
  end

  test "matching compliance values do not create a new compliance info row or submit to Stripe" do
    user = users(:compliance_test_user)
    compliance_info = build_individual_compliance_info(user)
    compliance_info.save!

    request = UserComplianceInfoRequest.create!(user: user, field_needed: UserComplianceInfoFields::Individual::Address::STREET)

    params = ActionController::Parameters.new(
      first_name: compliance_info.first_name,
      last_name: compliance_info.last_name,
      street_address: compliance_info.street_address,
      city: compliance_info.city,
      state: compliance_info.state,
      zip_code: compliance_info.zip_code,
      country: compliance_info.country_code,
      business_country: compliance_info.country_code,
      is_business: false,
      ssn_last_four: "000000000",
      dob_month: compliance_info.birthday.month.to_s,
      dob_day: compliance_info.birthday.day.to_s,
      dob_year: compliance_info.birthday.year.to_s,
      phone: compliance_info.phone,
    )

    StripeMerchantAccountManager.stub(:handle_new_user_compliance_info, ->(*) { raise "should not be called" }) do
      count_before = UserComplianceInfo.count
      result = UpdateUserComplianceInfo.new(compliance_params: params, user: user).process
      assert_equal count_before, UserComplianceInfo.count
      assert_equal true, result[:success]
    end

    assert_equal compliance_info.id, user.reload.alive_user_compliance_info.id
    assert_equal "provided", request.reload.state
  end

  test "changed compliance values create a new compliance info row and submit it to Stripe" do
    user = users(:compliance_test_user)
    compliance_info = build_individual_compliance_info(user)
    compliance_info.save!

    params = ActionController::Parameters.new(first_name: "Morgan")

    captured = nil
    StripeMerchantAccountManager.stub(:handle_new_user_compliance_info, ->(new_compliance_info) { captured = new_compliance_info }) do
      assert_difference -> { UserComplianceInfo.count }, 1 do
        result = UpdateUserComplianceInfo.new(compliance_params: params, user: user).process
        assert_equal true, result[:success]
      end
    end

    assert_equal "Morgan", captured.first_name
    assert_equal "Morgan", user.reload.alive_user_compliance_info.first_name
    refute_equal compliance_info.id, user.alive_user_compliance_info.id
  end

  test "US business with 9-digit business_tax_id accepts a non-tax-id field update without re-submitting" do
    us_business_user = build_us_business_user
    params = ActionController::Parameters.new(is_business: true, business_street_address: "456 Updated Street")

    result = UpdateUserComplianceInfo.new(compliance_params: params, user: us_business_user).process
    assert_equal true, result[:success]
    assert_equal "456 Updated Street", us_business_user.alive_user_compliance_info.business_street_address
  end

  test "rejects a too-short business_tax_id submitted in the same request" do
    us_business_user = build_us_business_user
    params = ActionController::Parameters.new(is_business: true, business_tax_id: "12345")
    result = UpdateUserComplianceInfo.new(compliance_params: params, user: us_business_user).process
    assert_equal false, result[:success]
    assert_equal "US business tax IDs (EIN) must have 9 digits.", result[:error_message]
  end

  test "accepts a 9-digit business_tax_id submitted with formatting" do
    us_business_user = build_us_business_user
    params = ActionController::Parameters.new(is_business: true, business_tax_id: "12-3456789")
    result = UpdateUserComplianceInfo.new(compliance_params: params, user: us_business_user).process
    assert_equal true, result[:success]
  end

  test "ignores a masked business_tax_id resubmission (containing bullet characters)" do
    us_business_user = build_us_business_user
    params = ActionController::Parameters.new(
      is_business: true,
      business_street_address: "456 Updated Street",
      business_tax_id: "\u2022\u2022-\u2022\u2022\u2022\u20221234",
    )
    result = UpdateUserComplianceInfo.new(compliance_params: params, user: us_business_user).process
    assert_equal true, result[:success]
    assert_equal "456 Updated Street", us_business_user.alive_user_compliance_info.business_street_address
  end

  test "ignores a masked individual_tax_id resubmission (containing asterisks)" do
    us_business_user = build_us_business_user
    params = ActionController::Parameters.new(
      is_business: true,
      business_street_address: "456 Updated Street",
      individual_tax_id: "***-**-1234",
    )
    result = UpdateUserComplianceInfo.new(compliance_params: params, user: us_business_user).process
    assert_equal true, result[:success]
  end

  test "preserves trailing letters in an Irish business_tax_id" do
    user = build_ie_business_user(business_tax_id: "000000000")
    params = ActionController::Parameters.new(is_business: true, business_tax_id: "3490731JH")

    captured = nil
    StripeMerchantAccountManager.stub(:handle_new_user_compliance_info, ->(new_info) { captured = new_info }) do
      result = UpdateUserComplianceInfo.new(compliance_params: params, user: user).process
      assert_equal true, result[:success]
    end

    stored = captured.business_tax_id.decrypt(GlobalConfig.get("STRONGBOX_GENERAL_PASSWORD"))
    assert_equal "3490731JH", stored

    stored = user.reload.alive_user_compliance_info.business_tax_id.decrypt(GlobalConfig.get("STRONGBOX_GENERAL_PASSWORD"))
    assert_equal "3490731JH", stored
  end

  test "detects re-adding trailing letters as a change after the bug previously stripped them" do
    user = build_ie_business_user(business_tax_id: "3490731")
    params = ActionController::Parameters.new(is_business: true, business_tax_id: "3490731JH")

    called = false
    StripeMerchantAccountManager.stub(:handle_new_user_compliance_info, ->(*) { called = true }) do
      assert_difference -> { UserComplianceInfo.count }, 1 do
        result = UpdateUserComplianceInfo.new(compliance_params: params, user: user).process
        assert_equal true, result[:success]
      end
    end
    assert called

    stored = user.reload.alive_user_compliance_info.business_tax_id.decrypt(GlobalConfig.get("STRONGBOX_GENERAL_PASSWORD"))
    assert_equal "3490731JH", stored
  end

  test "strips internal and surrounding whitespace but preserves alphanumeric characters" do
    user = build_ie_business_user(business_tax_id: "000000000")
    params = ActionController::Parameters.new(is_business: true, business_tax_id: "  3490731 JH  ")

    StripeMerchantAccountManager.stub(:handle_new_user_compliance_info, ->(*) {}) do
      result = UpdateUserComplianceInfo.new(compliance_params: params, user: user).process
      assert_equal true, result[:success]
    end

    stored = user.reload.alive_user_compliance_info.business_tax_id.decrypt(GlobalConfig.get("STRONGBOX_GENERAL_PASSWORD"))
    assert_equal "3490731JH", stored
  end

  test "collapses internal whitespace in a UK UTR-style business_tax_id" do
    user = users(:compliance_test_uk_business_user)
    info = UserComplianceInfo.new
    info.user = user
    info.first_name = "Chuck"
    info.last_name = "Bartowski"
    info.street_address = "address_full_match"
    info.city = "London"
    info.state = "London"
    info.zip_code = "SW1A 1AA"
    info.country = "United Kingdom"
    info.is_business = true
    info.business_name = "Buy More, LLC"
    info.business_street_address = "address_full_match"
    info.business_city = "London"
    info.business_state = "London"
    info.business_zip_code = "SW1A 1AA"
    info.business_country = "United Kingdom"
    info.business_type = UserComplianceInfo::BusinessTypes::CORPORATION
    info.business_tax_id = "0000000000"
    info.birthday = Date.new(1901, 1, 1)
    info.individual_tax_id = "000000000"
    info.save!

    params = ActionController::Parameters.new(is_business: true, business_tax_id: "1234 5678 90")

    StripeMerchantAccountManager.stub(:handle_new_user_compliance_info, ->(*) {}) do
      result = UpdateUserComplianceInfo.new(compliance_params: params, user: user).process
      assert_equal true, result[:success]
    end

    stored = user.reload.alive_user_compliance_info.business_tax_id.decrypt(GlobalConfig.get("STRONGBOX_GENERAL_PASSWORD"))
    assert_equal "1234567890", stored
  end

  test "collapses dashes in a non-US business_tax_id" do
    user = build_ie_business_user(business_tax_id: "000000000")
    params = ActionController::Parameters.new(is_business: true, business_tax_id: "3490-731-JH")

    StripeMerchantAccountManager.stub(:handle_new_user_compliance_info, ->(*) {}) do
      result = UpdateUserComplianceInfo.new(compliance_params: params, user: user).process
      assert_equal true, result[:success]
    end

    stored = user.reload.alive_user_compliance_info.business_tax_id.decrypt(GlobalConfig.get("STRONGBOX_GENERAL_PASSWORD"))
    assert_equal "3490731JH", stored
  end

  private

  def build_individual_compliance_info(user)
    info = UserComplianceInfo.new
    info.user = user
    info.first_name = "Chuck"
    info.last_name = "Bartowski"
    info.street_address = "address_full_match"
    info.city = "San Francisco"
    info.state = "California"
    info.zip_code = "94107"
    info.country = "United States"
    info.is_business = false
    info.has_sold_before = false
    info.individual_tax_id = "000000000"
    info.birthday = Date.new(1901, 1, 1)
    info.dba = "Chuckster"
    info.phone = "0000000000"
    info
  end

  def build_us_business_user
    user = users(:compliance_test_us_business_user)
    info = build_individual_compliance_info(user)
    info.is_business = true
    info.business_name = "Buy More, LLC"
    info.business_street_address = "address_full_match"
    info.business_city = "Burbank"
    info.business_state = "California"
    info.business_zip_code = "91506"
    info.business_country = "United States"
    info.business_type = UserComplianceInfo::BusinessTypes::LLC
    info.business_tax_id = "000000000"
    info.dba = "Buy Moria"
    info.business_phone = "0000000000"
    info.save!
    user
  end

  def build_ie_business_user(business_tax_id:)
    user = users(:compliance_test_ie_business_user)
    info = build_individual_compliance_info(user)
    info.city = "Dublin"
    info.state = "D"
    info.zip_code = "D02 XE80"
    info.country = "Ireland"
    info.is_business = true
    info.business_name = "Buy More, LLC"
    info.business_street_address = "address_full_match"
    info.business_city = "Dublin"
    info.business_state = "D"
    info.business_zip_code = "D02 XE80"
    info.business_country = "Ireland"
    info.business_type = UserComplianceInfo::BusinessTypes::CORPORATION
    info.business_tax_id = business_tax_id
    info.dba = "Buy Moria"
    info.business_phone = "0000000000"
    info.save!
    user
  end
end
