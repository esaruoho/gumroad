# frozen_string_literal: true

require "test_helper"

class ProductRefundPolicyTest < ActiveSupport::TestCase
  setup do
    @product = links(:named_seller_product)
    @seller = users(:named_seller)
  end

  def build_policy(**attrs)
    ProductRefundPolicy.new({
      product: @product,
      seller: @seller,
      max_refund_period_in_days: RefundPolicy::DEFAULT_REFUND_PERIOD_IN_DAYS,
      fine_print: "This is a product-level refund policy",
    }.merge(attrs))
  end

  def create_policy(**attrs)
    policy = build_policy(**attrs)
    policy.save!
    policy
  end

  # ---- validations ----

  test "validates presence of seller and product" do
    refund_policy = ProductRefundPolicy.new
    refute refund_policy.valid?
    assert_equal :blank, refund_policy.errors.details[:seller].first[:error]
    assert_equal :blank, refund_policy.errors.details[:product].first[:error]
  end

  test "validates product uniqueness" do
    refund_policy = create_policy
    duplicate = refund_policy.dup
    refute duplicate.valid?
    assert_equal :taken, duplicate.errors.details[:product].first[:error]
  end

  test "validates fine_print length" do
    refund_policy = create_policy
    refund_policy.fine_print = "a" * 3001
    refute refund_policy.valid?
    assert_equal :too_long, refund_policy.errors.details[:fine_print].first[:error]
  end

  test "strips tags" do
    refund_policy = create_policy
    refund_policy.fine_print = "<p>This is a product-level refund policy</p>"
    refund_policy.save!
    assert_equal "This is a product-level refund policy", refund_policy.fine_print
  end

  test "is invalid when the product does not belong to the seller" do
    refund_policy = create_policy
    refund_policy.product = links(:another_seller_product)
    refute refund_policy.valid?
    assert_equal :invalid, refund_policy.errors.details[:product].first[:error]
  end

  test "max_refund_period_in_days valid with all allowed values" do
    refund_policy = create_policy
    RefundPolicy::ALLOWED_REFUND_PERIODS_IN_DAYS.keys.each do |days|
      refund_policy.max_refund_period_in_days = days
      assert refund_policy.valid?, "Expected refund period #{days} to be valid"
    end
  end

  test "max_refund_period_in_days invalid with nil value" do
    refund_policy = create_policy
    refund_policy.max_refund_period_in_days = nil
    refute refund_policy.valid?
    assert_equal :inclusion, refund_policy.errors.details[:max_refund_period_in_days].first[:error]
  end

  test "max_refund_period_in_days invalid with disallowed values" do
    refund_policy = create_policy
    [1, 15, 60, 200].each do |days|
      refund_policy.max_refund_period_in_days = days
      refute refund_policy.valid?, "Expected refund period #{days} to be invalid"
      assert_equal :inclusion, refund_policy.errors.details[:max_refund_period_in_days].first[:error]
    end
  end

  # ---- stripped_fields ----

  test "strips leading and trailing spaces for fine_print" do
    refund_policy = create_policy(fine_print: "  This is a product-level refund policy  ")
    assert_equal "This is a product-level refund policy", refund_policy.fine_print
  end

  test "nullifies fine_print when blank" do
    refund_policy = create_policy(fine_print: "")
    assert_nil refund_policy.fine_print
  end

  # ---- #as_json ----

  test "#as_json returns a hash with refund details" do
    refund_policy = create_policy
    assert_equal({
      fine_print: refund_policy.fine_print,
      id: refund_policy.external_id,
      max_refund_period_in_days: refund_policy.max_refund_period_in_days,
      product_name: refund_policy.product.name,
      title: refund_policy.title,
    }, refund_policy.as_json)
  end

  # ---- scopes ----

  test "for_visible_and_not_archived_products only returns policies on visible/non-archived products" do
    visible_policy = create_policy

    archived_product = links(:another_seller_product)
    archived_product.archived = true
    archived_product.save!(validate: false)
    ProductRefundPolicy.create!(
      product: archived_product, seller: archived_product.user,
      max_refund_period_in_days: 30, fine_print: "x"
    )

    # Deleted: need a third product. Use existing fixture, mark deleted.
    deleted_product = nil
    user = users(:basic_user)
    deleted_product = Link.new(
      user: user, name: "soft-del", unique_permalink: "softdel#{SecureRandom.hex(2)}",
      price_cents: 100, deleted_at: Time.current
    )
    deleted_product.save!(validate: false)
    Price.create!(link: deleted_product, price_cents: 100, currency: "usd", flags: 0)
    ProductRefundPolicy.create!(
      product: deleted_product, seller: user,
      max_refund_period_in_days: 30, fine_print: "y"
    )

    assert_equal [visible_policy], ProductRefundPolicy.for_visible_and_not_archived_products.to_a
  end

  # ---- #no_refunds? ----

  test "#no_refunds? returns true when max_refund_period_in_days is 0" do
    refund_policy = create_policy
    refund_policy.max_refund_period_in_days = 0
    assert refund_policy.no_refunds?
  end

  test "#no_refunds? returns false for non-zero refund periods" do
    refund_policy = create_policy
    WebMock.stub_request(:post, "https://api.openai.com/v1/chat/completions").to_return(
      status: 200,
      body: { choices: [{ message: { content: '{"no_refunds": false}' } }] }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
    [7, 14, 30, 183].each do |days|
      refund_policy.max_refund_period_in_days = days
      refute refund_policy.no_refunds?, "Expected period #{days} to allow refunds"
    end
  end

  # ---- #published_and_no_refunds? ----

  test "#published_and_no_refunds? true when product published and no_refunds?" do
    refund_policy = create_policy
    refund_policy.product.define_singleton_method(:published?) { true }
    refund_policy.define_singleton_method(:no_refunds?) { true }
    assert refund_policy.published_and_no_refunds?
  end

  test "#published_and_no_refunds? false when product not published" do
    refund_policy = create_policy
    refund_policy.product.define_singleton_method(:published?) { false }
    refund_policy.define_singleton_method(:no_refunds?) { true }
    refute refund_policy.published_and_no_refunds?
  end

  test "#published_and_no_refunds? false when refunds are allowed" do
    refund_policy = create_policy
    refund_policy.product.define_singleton_method(:published?) { true }
    refund_policy.define_singleton_method(:no_refunds?) { false }
    refute refund_policy.published_and_no_refunds?
  end
end
