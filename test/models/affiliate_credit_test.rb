# frozen_string_literal: true

require "test_helper"

class AffiliateCreditTest < ActiveSupport::TestCase
  # ---- associations ----

  test "belongs to seller (User), required" do
    assoc = AffiliateCredit.reflect_on_association(:seller)
    assert_equal :belongs_to, assoc.macro
    assert_equal "User", assoc.class_name
    assert_not assoc.options[:optional]
  end

  test "belongs to affiliate_user (User), required" do
    assoc = AffiliateCredit.reflect_on_association(:affiliate_user)
    assert_equal :belongs_to, assoc.macro
    assert_equal "User", assoc.class_name
    assert_not assoc.options[:optional]
  end

  test "belongs to purchase, required" do
    assoc = AffiliateCredit.reflect_on_association(:purchase)
    assert_equal :belongs_to, assoc.macro
    assert_not assoc.options[:optional]
  end

  test "belongs to link, optional" do
    assoc = AffiliateCredit.reflect_on_association(:link)
    assert_equal :belongs_to, assoc.macro
    assert assoc.options[:optional]
  end

  test "belongs to affiliate, optional" do
    assoc = AffiliateCredit.reflect_on_association(:affiliate)
    assert_equal :belongs_to, assoc.macro
    assert assoc.options[:optional]
  end

  test "belongs to oauth_application, optional" do
    assoc = AffiliateCredit.reflect_on_association(:oauth_application)
    assert_equal :belongs_to, assoc.macro
    assert assoc.options[:optional]
  end

  # ---- validations ----

  def build_credit(attrs = {})
    AffiliateCredit.new({
      affiliate_user: users(:basic_user),
      seller: users(:named_seller),
      purchase: purchases(:aff_credit_test_partials_purchase),
      link: links(:named_seller_product),
      affiliate: affiliates(:aff_credit_test_direct_affiliate_per_product),
      basis_points: 1000,
    }.merge(attrs))
  end

  test "validates presence of basis_points" do
    credit = build_credit(basis_points: nil)
    assert_not credit.valid?
    assert_includes credit.errors[:basis_points], "can't be blank"
  end

  test "validates basis_points numericality bounds (>= 0)" do
    credit = build_credit(basis_points: -1)
    assert_not credit.valid?
    assert_not_empty credit.errors[:basis_points]
  end

  test "validates basis_points numericality bounds (<= 100_00)" do
    credit = build_credit(basis_points: 100_01)
    assert_not credit.valid?
    assert_not_empty credit.errors[:basis_points]
  end

  test "requires an affiliate or oauth application to be present" do
    no_either = build_credit(affiliate: nil)
    no_either.oauth_application = nil
    assert_not no_either.valid?

    with_oauth = build_credit(affiliate: nil)
    with_oauth.oauth_application = oauth_applications(:aff_credit_test_oauth_app)
    assert with_oauth.valid?, "expected with_oauth to be valid; errors=#{with_oauth.errors.full_messages}"

    with_affiliate_only = build_credit
    with_affiliate_only.oauth_application = nil
    assert with_affiliate_only.valid?
  end

  # ---- partial refund sums ----

  test "#amount_partially_refunded_cents returns the sum of amount_cents of affiliate_partial_refunds" do
    credit = affiliate_credits(:aff_credit_test_partials_credit)
    assert_equal 0, credit.amount_partially_refunded_cents

    AffiliatePartialRefund.create!(
      affiliate_credit: credit,
      affiliate_user: credit.affiliate_user,
      seller: credit.seller,
      purchase: credit.purchase,
      affiliate: credit.affiliate,
      balance: balances(:aff_credit_test_balance),
      amount_cents: 12,
    )
    AffiliatePartialRefund.create!(
      affiliate_credit: credit,
      affiliate_user: credit.affiliate_user,
      seller: credit.seller,
      purchase: credit.purchase,
      affiliate: credit.affiliate,
      balance: balances(:aff_credit_test_balance),
      amount_cents: 34,
    )
    assert_equal 46, credit.reload.amount_partially_refunded_cents
  end

  test "#fee_partially_refunded_cents returns the sum of fee_cents of affiliate_partial_refunds" do
    credit = affiliate_credits(:aff_credit_test_partials_credit)
    assert_equal 0, credit.fee_partially_refunded_cents

    AffiliatePartialRefund.create!(
      affiliate_credit: credit,
      affiliate_user: credit.affiliate_user,
      seller: credit.seller,
      purchase: credit.purchase,
      affiliate: credit.affiliate,
      balance: balances(:aff_credit_test_balance),
      fee_cents: 12,
    )
    AffiliatePartialRefund.create!(
      affiliate_credit: credit,
      affiliate_user: credit.affiliate_user,
      seller: credit.seller,
      purchase: credit.purchase,
      affiliate: credit.affiliate,
      balance: balances(:aff_credit_test_balance),
      fee_cents: 34,
    )
    assert_equal 46, credit.reload.fee_partially_refunded_cents
  end

  # ---- AffiliateCredit.create! ----

  test ".create! uses product commission when affiliate does not apply to all products" do
    affiliate = affiliates(:aff_credit_test_direct_affiliate_per_product)
    purchase = purchases(:aff_credit_test_purchase_per_product)
    balance = balances(:aff_credit_test_balance)

    credit = AffiliateCredit.create!(
      purchase:,
      affiliate:,
      affiliate_amount_cents: 20,
      affiliate_fee_cents: 5,
      affiliate_balance: balance,
    )
    assert_equal 20, credit.amount_cents
    assert_equal 5, credit.fee_cents
    assert_equal 2000, credit.basis_points
  end

  test ".create! uses affiliate commission when affiliate applies to all products" do
    affiliate = affiliates(:aff_credit_test_direct_affiliate_all_products)
    purchase = purchases(:aff_credit_test_purchase_all_products)
    balance = balances(:aff_credit_test_balance)

    credit = AffiliateCredit.create!(
      purchase:,
      affiliate:,
      affiliate_amount_cents: 10,
      affiliate_fee_cents: 5,
      affiliate_balance: balance,
    )
    assert_equal 10, credit.amount_cents
    assert_equal 5, credit.fee_cents
    assert_equal affiliate.affiliate_basis_points, credit.basis_points
  end

  test ".create! falls back to affiliate commission when no product commission row exists" do
    affiliate = affiliates(:aff_credit_test_direct_affiliate_all_products)
    purchase = purchases(:aff_credit_test_purchase_all_products)
    balance = balances(:aff_credit_test_balance)

    credit = AffiliateCredit.create!(
      purchase:,
      affiliate:,
      affiliate_amount_cents: 10,
      affiliate_fee_cents: 5,
      affiliate_balance: balance,
    )
    assert_equal 10, credit.amount_cents
    assert_equal 5, credit.fee_cents
    assert_equal affiliate.affiliate_basis_points, credit.basis_points
  end
end
