# frozen_string_literal: true

require "test_helper"

class StripeBeneficialOwnersManagerTest < ActiveSupport::TestCase
  fixtures :users

  # ---- Helpers ----

  def build_business_user_with_stripe_account
    user = users(:basic_user)
    UserComplianceInfo.create!(
      user: user,
      country: "United States",
      first_name: "Biz",
      last_name: "Owner",
      business_name: "Acme LLC",
      business_type: "llc",
      is_business: true
    )
    ma = MerchantAccount.create!(
      user: user,
      charge_processor_id: StripeChargeProcessor.charge_processor_id,
      charge_processor_merchant_id: "acct_test_#{SecureRandom.hex(4)}",
      charge_processor_alive_at: 1.day.ago,
      country: "US",
      currency: "usd"
    )
    user.reload
    [user, ma]
  end

  # ---- eligible? ----

  test ".eligible? is false when the user has no stripe account" do
    refute StripeBeneficialOwnersManager.eligible?(users(:basic_user))
  end

  test ".eligible? is false when user has a stripe account but compliance info is not business" do
    user = users(:basic_user)
    UserComplianceInfo.create!(
      user: user,
      country: "United States",
      first_name: "Solo",
      last_name: "Trader"
    )
    MerchantAccount.create!(
      user: user,
      charge_processor_id: StripeChargeProcessor.charge_processor_id,
      charge_processor_merchant_id: "acct_solo_#{SecureRandom.hex(4)}",
      charge_processor_alive_at: 1.day.ago,
      country: "US",
      currency: "usd"
    )
    user.reload
    refute StripeBeneficialOwnersManager.eligible?(user)
  end

  test ".eligible? is true for a US business user with a non-connect stripe account" do
    user, _ma = build_business_user_with_stripe_account
    assert StripeBeneficialOwnersManager.eligible?(user)
  end

  # ---- NotEligibleError surface ----

  test ".list raises NotEligibleError for non-eligible users" do
    err = assert_raises(StripeBeneficialOwnersManager::NotEligibleError) do
      StripeBeneficialOwnersManager.list(users(:basic_user))
    end
    assert_match(/does not have a Gumroad-managed business Stripe account/, err.message)
  end

  test ".create raises NotEligibleError for non-eligible users" do
    assert_raises(StripeBeneficialOwnersManager::NotEligibleError) do
      StripeBeneficialOwnersManager.create(users(:basic_user), {})
    end
  end

  test ".destroy raises NotEligibleError for non-eligible users" do
    assert_raises(StripeBeneficialOwnersManager::NotEligibleError) do
      StripeBeneficialOwnersManager.destroy(users(:basic_user), "person_x")
    end
  end

  test ".update raises NotEligibleError for non-eligible users" do
    assert_raises(StripeBeneficialOwnersManager::NotEligibleError) do
      StripeBeneficialOwnersManager.update(users(:basic_user), "person_x", {})
    end
  end

  # ---- list / create / destroy happy paths (with Stripe API stubbed) ----

  test ".list returns serialized persons from Stripe::Account.list_persons" do
    user, ma = build_business_user_with_stripe_account

    person_hash = {
      "id" => "person_1",
      "first_name" => "Alice",
      "last_name" => "Anderson",
      "email" => "alice@example.com",
      "phone" => "+15551234567",
      "dob" => { "day" => 1, "month" => 2, "year" => 1980 },
      "address" => { "country" => "US" },
      "relationship" => { "owner" => true, "title" => "CEO", "representative" => false },
      "id_number_provided" => true,
      "verification" => { "status" => "verified" },
      "requirements" => { "currently_due" => [] }
    }
    stripe_resp = { "data" => [person_hash] }

    captured = []
    original = Stripe::Account.method(:list_persons)
    Stripe::Account.define_singleton_method(:list_persons) do |acct_id, **opts|
      captured << [acct_id, opts]
      stripe_resp
    end
    begin
      result = StripeBeneficialOwnersManager.list(user)
      assert_equal 1, result.length
      assert_equal "person_1", result.first[:id]
      assert_equal "Alice", result.first[:first_name]
      assert_equal({ day: 1, month: 2, year: 1980 }, result.first[:dob])
      assert_equal true, result.first[:relationship][:owner]
      assert_equal "verified", result.first[:verification_status]
      assert_equal [ma.charge_processor_merchant_id, { limit: 100 }], captured.first
    ensure
      Stripe::Account.define_singleton_method(:list_persons, original)
    end
  end

  test ".create raises MissingRequiredFieldError when required fields are missing" do
    user, _ma = build_business_user_with_stripe_account
    assert_raises(StripeBeneficialOwnersManager::MissingRequiredFieldError) do
      StripeBeneficialOwnersManager.create(user, { first_name: "Alice" })
    end
  end

  test ".destroy refuses to delete a stripe representative" do
    user, ma = build_business_user_with_stripe_account
    rep_person = { "id" => "person_rep", "relationship" => { "representative" => true } }

    original = Stripe::Account.method(:retrieve_person)
    Stripe::Account.define_singleton_method(:retrieve_person) { |_acct, _pid| rep_person }
    begin
      assert_raises(StripeBeneficialOwnersManager::RepresentativeNotEditableError) do
        StripeBeneficialOwnersManager.destroy(user, "person_rep")
      end
      assert_equal "acct_test_", ma.charge_processor_merchant_id[0, 10]
    ensure
      Stripe::Account.define_singleton_method(:retrieve_person, original)
    end
  end

  test ".destroy deletes a non-representative person and returns a {deleted:true,id:} hash" do
    user, _ma = build_business_user_with_stripe_account
    non_rep_person = { "id" => "person_bo", "relationship" => { "owner" => true } }

    retrieve_orig = Stripe::Account.method(:retrieve_person)
    delete_orig = Stripe::Account.method(:delete_person)
    delete_called_with = []
    Stripe::Account.define_singleton_method(:retrieve_person) { |_acct, _pid| non_rep_person }
    Stripe::Account.define_singleton_method(:delete_person) do |acct, pid|
      delete_called_with << [acct, pid]
      { "id" => pid, "deleted" => true }
    end
    begin
      result = StripeBeneficialOwnersManager.destroy(user, "person_bo")
      assert_equal({ deleted: true, id: "person_bo" }, result)
      assert_equal 1, delete_called_with.length
      assert_equal "person_bo", delete_called_with.first.last
    ensure
      Stripe::Account.define_singleton_method(:retrieve_person, retrieve_orig)
      Stripe::Account.define_singleton_method(:delete_person, delete_orig)
    end
  end
end
