# frozen_string_literal: true

require "test_helper"

class Admin::RelatedUsersServiceTest < ActiveSupport::TestCase
  setup do
    WebMock.stub_request(:get, %r{api\.pwnedpasswords\.com/range/.*}).to_return(status: 200, body: "")
    # Pre-existing fixture users carry assorted IPs / payment_addresses;
    # neutralize them so the service's queries only see what this test seeds.
    User.update_all(account_created_ip: nil, current_sign_in_ip: nil, last_sign_in_ip: nil, payment_address: nil)
    CreditCard.update_all(stripe_fingerprint: nil)
  end

  def make_user(**attrs)
    creds = attrs.delete(:credit_card)
    user = User.create!(
      {
        email: "rel-#{SecureRandom.hex(6)}@example.com",
        password: "test-password-123!",
        confirmed_at: Time.current,
        user_risk_state: "not_reviewed",
        recommendation_type: User::RecommendationType::OWN_PRODUCTS,
        credit_card_id: creds&.id,
        created_at: Time.current,
        updated_at: Time.current,
      }.merge(attrs)
    )
    user
  end

  def make_credit_card(fingerprint)
    CreditCard.create!(
      stripe_fingerprint: fingerprint,
      visual: "**** **** **** 4242",
      card_type: CardType::VISA,
      stripe_customer_id: "cus_#{SecureRandom.hex(6)}",
      expiry_month: 12,
      expiry_year: 2030,
      charge_processor_id: StripeChargeProcessor.charge_processor_id,
    )
  end

  def related_user_payload(result, user)
    result.related_users.find { |ru| ru[:id] == user.external_id }
  end

  test "returns users sharing any target IP with the matching columns" do
    target = make_user(current_sign_in_ip: "1.2.3.4")
    created_match = make_user(account_created_ip: "1.2.3.4")
    last_match = make_user(last_sign_in_ip: "1.2.3.4")
    make_user(last_sign_in_ip: "5.6.7.8")

    result = Admin::RelatedUsersService.new(target, signals: ["ip"]).call

    assert_equal ["ip"], result.signals_evaluated
    ids = result.related_users.map { |ru| ru[:id] }
    assert_equal [created_match.external_id, last_match.external_id].sort, ids.sort
    payload = related_user_payload(result, created_match)
    assert_equal [{ signal: "ip", shared_value: "1.2.3.4", via: ["account_created_ip", "current_sign_in_ip"] }], payload[:relations]
    payload = related_user_payload(result, last_match)
    assert_equal [{ signal: "ip", shared_value: "1.2.3.4", via: ["current_sign_in_ip", "last_sign_in_ip"] }], payload[:relations]
  end

  test "aggregates IP via columns for a related user matching the same shared value multiple ways" do
    target = make_user(account_created_ip: "1.2.3.4")
    related = make_user(account_created_ip: "1.2.3.4", current_sign_in_ip: "1.2.3.4")

    result = Admin::RelatedUsersService.new(target, signals: ["ip"]).call
    payload = related_user_payload(result, related)
    assert_equal [{ signal: "ip", shared_value: "1.2.3.4", via: ["account_created_ip", "current_sign_in_ip"] }], payload[:relations]
  end

  test "returns users sharing the target payment address" do
    target = make_user(payment_address: "shared@example.com")
    related = make_user(payment_address: "shared@example.com")
    make_user(payment_address: "other@example.com")

    result = Admin::RelatedUsersService.new(target, signals: ["payment_address"]).call

    assert_equal ["payment_address"], result.signals_evaluated
    assert_equal [related.external_id], result.related_users.map { |ru| ru[:id] }
    assert_equal [{ signal: "payment_address", shared_value: "shared@example.com" }], result.related_users.first[:relations]
  end

  test "skips payment address when the target has no payment address" do
    target = make_user(payment_address: nil)
    make_user(payment_address: nil)

    result = Admin::RelatedUsersService.new(target, signals: ["payment_address"]).call

    assert_equal [], result.signals_evaluated
    assert_equal [], result.related_users
    assert_equal({ "payment_address" => false }, result.truncated)
  end

  test "returns users sharing the target card fingerprint without exposing the fingerprint value" do
    target = make_user(credit_card: make_credit_card("fp_shared"))
    a = make_user(credit_card: make_credit_card("fp_shared"))
    b = make_user(credit_card: make_credit_card("fp_shared"))
    make_user(credit_card: make_credit_card("fp_other"))

    result = Admin::RelatedUsersService.new(target, signals: ["card_fingerprint"]).call

    assert_equal ["card_fingerprint"], result.signals_evaluated
    ids = result.related_users.map { |ru| ru[:id] }
    assert_equal [a.external_id, b.external_id].sort, ids.sort
    relations = result.related_users.flat_map { |ru| ru[:relations] }
    assert relations.all? { |r| r == { signal: "card_fingerprint", shared_value: nil } }
  end

  test "skips card fingerprint when the target has no credit card" do
    target = make_user(payment_address: nil)
    result = Admin::RelatedUsersService.new(target, signals: ["card_fingerprint"]).call

    assert_equal [], result.signals_evaluated
    assert_equal [], result.related_users
    assert_equal({ "card_fingerprint" => false }, result.truncated)
  end

  test "deduplicates by user and ranks users matching more distinct signals first" do
    target = make_user(account_created_ip: "1.2.3.4", payment_address: "shared@example.com")
    multi = make_user(account_created_ip: "1.2.3.4", payment_address: "shared@example.com")
    multi.update_columns(updated_at: 2.days.ago)
    single = make_user(account_created_ip: "1.2.3.4", payment_address: "other@example.com")
    single.update_columns(updated_at: 1.hour.ago)

    result = Admin::RelatedUsersService.new(target, signals: %w[ip payment_address]).call

    ids = result.related_users.map { |ru| ru[:id] }
    assert_equal [multi.external_id, single.external_id], ids
    multi_signals = result.related_users.first[:relations].map { |r| r[:signal] }
    assert_equal ["ip", "payment_address"].sort, multi_signals.sort
  end

  test "caps the IP signal to the most recently updated matches and reports truncation" do
    target = make_user(account_created_ip: "1.2.3.4")
    oldest = make_user(account_created_ip: "1.2.3.4"); oldest.update_columns(updated_at: 3.days.ago)
    middle = make_user(account_created_ip: "1.2.3.4"); middle.update_columns(updated_at: 2.days.ago)
    newest = make_user(account_created_ip: "1.2.3.4"); newest.update_columns(updated_at: 1.day.ago)

    result = Admin::RelatedUsersService.new(target, signals: ["ip"], limit: 2).call

    ids = result.related_users.map { |ru| ru[:id] }
    assert_equal [newest.external_id, middle.external_id], ids
    refute_includes ids, oldest.external_id
    assert_equal({ "ip" => true }, result.truncated)
  end

  test "caps the payment address signal to the most recently updated matches" do
    target = make_user(payment_address: "shared@example.com")
    oldest = make_user(payment_address: "shared@example.com"); oldest.update_columns(updated_at: 3.days.ago)
    middle = make_user(payment_address: "shared@example.com"); middle.update_columns(updated_at: 2.days.ago)
    newest = make_user(payment_address: "shared@example.com"); newest.update_columns(updated_at: 1.day.ago)

    result = Admin::RelatedUsersService.new(target, signals: ["payment_address"], limit: 2).call
    ids = result.related_users.map { |ru| ru[:id] }
    assert_equal [newest.external_id, middle.external_id], ids
    refute_includes ids, oldest.external_id
    assert_equal({ "payment_address" => true }, result.truncated)
  end

  test "caps the card fingerprint signal to the most recently updated matches" do
    target = make_user(credit_card: make_credit_card("fp_shared"))
    oldest = make_user(credit_card: make_credit_card("fp_shared")); oldest.update_columns(updated_at: 3.days.ago)
    middle = make_user(credit_card: make_credit_card("fp_shared")); middle.update_columns(updated_at: 2.days.ago)
    newest = make_user(credit_card: make_credit_card("fp_shared")); newest.update_columns(updated_at: 1.day.ago)

    result = Admin::RelatedUsersService.new(target, signals: ["card_fingerprint"], limit: 2).call
    ids = result.related_users.map { |ru| ru[:id] }
    assert_equal [newest.external_id, middle.external_id], ids
    refute_includes ids, oldest.external_id
    assert_equal({ "card_fingerprint" => true }, result.truncated)
  end

  test "excludes the target user from related users" do
    target = make_user(account_created_ip: "1.2.3.4", payment_address: "shared@example.com",
                       credit_card: make_credit_card("fp_shared"))

    result = Admin::RelatedUsersService.new(target).call
    assert_equal [], result.related_users
  end

  test "returns empty results when the target has no related signal values" do
    target = make_user(payment_address: nil)
    result = Admin::RelatedUsersService.new(target).call

    assert_equal [], result.signals_evaluated
    assert_equal [], result.related_users
    assert_equal({ "ip" => false, "payment_address" => false, "card_fingerprint" => false }, result.truncated)
  end
end
