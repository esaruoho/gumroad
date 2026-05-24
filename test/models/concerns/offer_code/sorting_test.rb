require "test_helper"

class OfferCode::SortingTest < ActiveSupport::TestCase
  setup do
    @seller = users(:named_seller)
    # Remove any pre-existing offer codes for this seller from other fixtures
    OfferCode.where(user_id: @seller.id).destroy_all
    @product1 = links(:named_seller_product)
    @product2 = Link.new(
      user: @seller,
      name: "Sorting product 2",
      unique_permalink: "spsp2",
      price_cents: 500,
      purchase_type: 0,
      native_type: "digital",
      filetype: "link",
      filegroup: "url",
    )
    @product2.save!(validate: false)

    tz = ActiveSupport::TimeZone[@seller.timezone || "UTC"]
    @offer_code1 = OfferCode.new(
      name: "Discount 1",
      code: "code1",
      user: @seller,
      amount_cents: 100,
      max_purchase_count: 12,
      valid_at: tz.parse("January 1 #{Time.current.year - 1}"),
      expires_at: tz.parse("February 1 #{Time.current.year - 1}"),
      products: [@product1, @product2],
    )
    @offer_code1.save!(validate: false)

    @offer_code2 = OfferCode.new(
      name: "Discount 2",
      code: "code2",
      user: @seller,
      amount_cents: 200,
      max_purchase_count: 20,
      valid_at: tz.parse("January 1 #{Time.current.year + 1}"),
      products: [@product2],
    )
    @offer_code2.save!(validate: false)

    @offer_code3 = OfferCode.new(
      name: "Discount 3",
      code: "code3",
      user: @seller,
      amount_percentage: 50,
      universal: true,
      products: [],
    )
    @offer_code3.save!(validate: false)

    10.times { build_purchase(@product1, @offer_code1) }
    5.times { build_purchase(@product2, @offer_code2) }
    build_purchase(@product1, @offer_code3)
    build_purchase(@product2, @offer_code3)
  end

  test "returns offer codes sorted by name" do
    assert_equal [@offer_code1, @offer_code2, @offer_code3],
                 @seller.offer_codes.sorted_by(key: "name", direction: "asc").to_a
    assert_equal [@offer_code3, @offer_code2, @offer_code1],
                 @seller.offer_codes.sorted_by(key: "name", direction: "desc").to_a
  end

  test "returns offer codes sorted by uses" do
    assert_equal [@offer_code3, @offer_code2, @offer_code1],
                 @seller.offer_codes.sorted_by(key: "uses", direction: "asc").to_a
    assert_equal [@offer_code1, @offer_code2, @offer_code3],
                 @seller.offer_codes.sorted_by(key: "uses", direction: "desc").to_a
  end

  test "returns offer codes sorted by revenue" do
    assert_equal [@offer_code3, @offer_code2, @offer_code1],
                 @seller.offer_codes.sorted_by(key: "uses", direction: "asc").to_a
    assert_equal [@offer_code1, @offer_code2, @offer_code3],
                 @seller.offer_codes.sorted_by(key: "uses", direction: "desc").to_a
  end

  test "returns offer codes sorted by term" do
    assert_equal [@offer_code3, @offer_code2, @offer_code1],
                 @seller.offer_codes.sorted_by(key: "uses", direction: "asc").to_a
    assert_equal [@offer_code1, @offer_code2, @offer_code3],
                 @seller.offer_codes.sorted_by(key: "uses", direction: "desc").to_a
  end

  private
    def build_purchase(product, offer_code)
      now = Time.current
      price = product.price_cents || 100
      Purchase.insert({
        seller_id: @seller.id,
        link_id: product.id,
        offer_code_id: offer_code.id,
        email: "buyer-#{SecureRandom.hex(4)}@example.com",
        price_cents: price,
        total_transaction_cents: price,
        displayed_price_cents: price,
        displayed_price_currency_type: "usd",
        purchase_state: "successful",
        succeeded_at: now,
        quantity: 1,
        created_at: now,
        updated_at: now,
      })
    end
end
