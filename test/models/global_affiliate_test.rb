# frozen_string_literal: true

require "test_helper"

class GlobalAffiliateTest < ActiveSupport::TestCase
  setup do
    @user = users(:basic_user)
    # `after_create :create_global_affiliate!` on User means our fixture sellers
    # don't get one — so create it here for tests that need a persisted row.
    @global_affiliate = @user.global_affiliate || @user.create_global_affiliate!
  end

  # --- validations: affiliate_basis_points ---

  test "requires affiliate_basis_points to be present" do
    @global_affiliate.affiliate_basis_points = nil
    refute @global_affiliate.valid?
    assert_includes @global_affiliate.errors.full_messages, "Affiliate basis points can't be blank"
  end

  # --- validations: affiliate_user_id uniqueness ---

  test "requires affiliate_user_id to be unique" do
    duplicate = GlobalAffiliate.new(affiliate_user: @user)
    refute duplicate.valid?
    assert_includes duplicate.errors.full_messages, "Affiliate user has already been taken"
  end

  test "allows multiple direct affiliates for the same user" do
    # Use a freshly-created user as affiliate_user so we don't collide with
    # `aff_credit_test_*` fixtures (DirectAffiliate uniqueness is scoped per seller).
    other_user = users(:purchaser)
    a1 = DirectAffiliate.new(affiliate_user: other_user, seller: users(:named_seller),
                             affiliate_basis_points: 1_000)
    a2 = DirectAffiliate.new(affiliate_user: other_user, seller: users(:another_seller),
                             affiliate_basis_points: 1_000)
    assert a1.valid?, a1.errors.full_messages.inspect
    assert a2.valid?, a2.errors.full_messages.inspect
  end

  # --- validation: eligible_for_stripe_payments (Brazilian Stripe Connect) ---

  test "invalid when affiliate user has a Brazilian Stripe Connect account" do
    @user.define_singleton_method(:has_brazilian_stripe_connect_account?) { true }
    new_affiliate = GlobalAffiliate.new(affiliate_user: @user)
    refute new_affiliate.valid?
    assert_includes new_affiliate.errors[:base],
                    "This user cannot be added as an affiliate because they use a Brazilian Stripe account."
  end

  # --- lifecycle hooks: before_validation set_affiliate_basis_points ---

  test "sets affiliate_basis_points to the default on a new record" do
    affiliate = GlobalAffiliate.new(affiliate_basis_points: nil)
    affiliate.valid?
    assert_equal GlobalAffiliate::AFFILIATE_BASIS_POINTS, affiliate.affiliate_basis_points
  end

  test "does not overwrite affiliate_basis_points for an existing record" do
    @global_affiliate.affiliate_basis_points = 5_000
    @global_affiliate.valid?
    assert_equal 5_000, @global_affiliate.affiliate_basis_points
  end

  # --- .cookie_lifetime ---

  test ".cookie_lifetime returns 7 days" do
    assert_equal 7.days, GlobalAffiliate.cookie_lifetime
  end

  # --- #final_destination_url ---

  test "#final_destination_url returns the product URL when product is provided" do
    product = links(:basic_user_product)
    assert_equal product.long_url, @global_affiliate.final_destination_url(product:)
  end

  test "#final_destination_url returns the discover URL when product is missing" do
    expected = "#{UrlService.discover_domain_with_protocol}/discover?a=#{@global_affiliate.external_id_numeric}"
    assert_equal expected, @global_affiliate.final_destination_url
  end
end
