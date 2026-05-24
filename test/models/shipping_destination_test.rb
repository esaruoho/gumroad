# frozen_string_literal: true

require "test_helper"

class ShippingDestinationTest < ActiveSupport::TestCase
  setup do
    @product = links(:basic_user_product)
  end

  test "does not allow saving if the country code is nil or invalid" do
    @product.shipping_destinations << ShippingDestination.new(country_code: "dummy",
                                                              one_item_rate_cents: 10,
                                                              multiple_items_rate_cents: 10)
    assert_not @product.valid?

    valid = ShippingDestination.new(country_code: Compliance::Countries::USA.alpha2,
                                    one_item_rate_cents: 10,
                                    multiple_items_rate_cents: 10)
    @product.reload.shipping_destinations << valid
    @product.save!

    assert_equal valid, @product.shipping_destinations.first
  end

  test "does not allow saving if the standalone rate or the combined rate is missing" do
    @product.shipping_destinations << ShippingDestination.new(country_code: Compliance::Countries::USA.alpha2,
                                                              one_item_rate_cents: 10)
    assert_not @product.valid?

    @product.reload.shipping_destinations << ShippingDestination.new(country_code: Compliance::Countries::USA.alpha2,
                                                                     multiple_items_rate_cents: 10)
    assert_not @product.valid?

    valid = ShippingDestination.new(country_code: Compliance::Countries::USA.alpha2,
                                    one_item_rate_cents: 10,
                                    multiple_items_rate_cents: 10)
    @product.reload.shipping_destinations << valid
    @product.save!

    assert_equal valid, @product.shipping_destinations.first
  end

  test "does not allow associating a single record with both a user and a product" do
    sd1 = ShippingDestination.new(country_code: Compliance::Countries::USA.alpha2, one_item_rate_cents: 10, multiple_items_rate_cents: 10)
    sd2 = ShippingDestination.new(country_code: Compliance::Countries::DEU.alpha2, one_item_rate_cents: 10, multiple_items_rate_cents: 10)

    @product.shipping_destinations << sd1
    @product.save!
    assert_equal sd1, @product.shipping_destinations.first

    @product.user.shipping_destinations << sd1
    @product.save!

    assert @product.reload.user.shipping_destinations.empty?

    @product.user.reload.shipping_destinations << sd2
    @product.save!

    assert_equal sd2, @product.user.shipping_destinations.first
  end

  test "does not allow duplicate entries for a country code for a product" do
    valid = ShippingDestination.new(country_code: Compliance::Countries::USA.alpha2,
                                    one_item_rate_cents: 20,
                                    multiple_items_rate_cents: 10)
    @product.shipping_destinations << valid
    @product.save!

    assert_equal valid, @product.shipping_destinations.first

    @product.shipping_destinations << ShippingDestination.new(country_code: Compliance::Countries::USA.alpha2,
                                                              one_item_rate_cents: 10,
                                                              multiple_items_rate_cents: 10)
    assert_not @product.valid?
  end

  test "does not allow duplicate entries for a country code for a user" do
    valid = ShippingDestination.new(country_code: ShippingDestination::Destinations::ELSEWHERE,
                                    one_item_rate_cents: 20,
                                    multiple_items_rate_cents: 10)
    @product.user.shipping_destinations << valid
    @product.save!

    assert_equal valid, @product.user.shipping_destinations.first

    @product.user.shipping_destinations << ShippingDestination.new(country_code: ShippingDestination::Destinations::ELSEWHERE,
                                                                   one_item_rate_cents: 10,
                                                                   multiple_items_rate_cents: 10)
    @product.save!
    assert_equal [valid], @product.user.reload.shipping_destinations.to_a
  end

  # --- #calculate_shipping_rate ---

  test "#calculate_shipping_rate returns nil for quantity < 1" do
    sd = ShippingDestination.new(country_code: Compliance::Countries::USA.alpha2, one_item_rate_cents: 20, multiple_items_rate_cents: 10)
    assert_nil sd.calculate_shipping_rate(quantity: -1)
  end

  test "#calculate_shipping_rate returns one_item_rate_cents for quantity = 1" do
    sd = ShippingDestination.new(country_code: Compliance::Countries::USA.alpha2, one_item_rate_cents: 20, multiple_items_rate_cents: 10)
    assert_equal 20, sd.calculate_shipping_rate(quantity: 1)
  end

  test "#calculate_shipping_rate returns one_item_rate_cents + (quantity-1)*multiple_items_rate_cents for quantity > 1" do
    sd = ShippingDestination.new(country_code: Compliance::Countries::USA.alpha2, one_item_rate_cents: 20, multiple_items_rate_cents: 10)
    assert_equal 30, sd.calculate_shipping_rate(quantity: 2)
    assert_equal 40, sd.calculate_shipping_rate(quantity: 3)
    assert_equal 70, sd.calculate_shipping_rate(quantity: 6)
  end

  # --- .for_product_and_country_code ---

  def make_link
    seller = users(:another_seller)
    link = Link.new(user: seller, name: "Shipping spec product", unique_permalink: "shpsdest#{SecureRandom.hex(4)}".tr("0-9", "abcdefghij"), price_cents: 100, native_type: "digital", filetype: "link", filegroup: "url")
    link.save!(validate: false)
    link
  end

  test "returns nil if the destination country code is nil or the product is not physical" do
    link = make_link
    assert_nil ShippingDestination.for_product_and_country_code(product: link, country_code: nil)

    sd = ShippingDestination.new(country_code: Compliance::Countries::USA.alpha2, one_item_rate_cents: 20, multiple_items_rate_cents: 10)
    link.shipping_destinations << sd
    link.is_physical = false
    link.save!(validate: false)

    assert_nil ShippingDestination.for_product_and_country_code(product: link.reload, country_code: Compliance::Countries::USA.alpha2)

    link.is_physical = true
    link.shipping_destinations << ShippingDestination.new(country_code: ShippingDestination::Destinations::ELSEWHERE, one_item_rate_cents: 0, multiple_items_rate_cents: 0)
    link.save!(validate: false)

    assert_equal sd, ShippingDestination.for_product_and_country_code(product: link, country_code: Compliance::Countries::USA.alpha2)
  end

  test "returns a configured shipping destination if there is a match" do
    link = make_link
    sd1 = ShippingDestination.new(country_code: Compliance::Countries::USA.alpha2, one_item_rate_cents: 20, multiple_items_rate_cents: 10)
    sd2 = ShippingDestination.new(country_code: Compliance::Countries::DEU.alpha2, one_item_rate_cents: 10, multiple_items_rate_cents: 5)
    sd3 = ShippingDestination.new(country_code: Compliance::Countries::GBR.alpha2, one_item_rate_cents: 10, multiple_items_rate_cents: 5)

    link.is_physical = true
    link.require_shipping = true
    link.shipping_destinations << sd1 << sd2 << sd3
    link.save!(validate: false)

    assert_equal sd1, ShippingDestination.for_product_and_country_code(product: link, country_code: Compliance::Countries::USA.alpha2)
    assert_equal sd2, ShippingDestination.for_product_and_country_code(product: link, country_code: Compliance::Countries::DEU.alpha2)
    assert_equal sd3, ShippingDestination.for_product_and_country_code(product: link, country_code: Compliance::Countries::GBR.alpha2)
    assert_nil ShippingDestination.for_product_and_country_code(product: link, country_code: Compliance::Countries::ESP.alpha2)
  end

  test "returns a match for any country if there is a configuration for ELSEWHERE" do
    link = make_link
    sd = ShippingDestination.new(country_code: ShippingDestination::Destinations::ELSEWHERE, one_item_rate_cents: 20, multiple_items_rate_cents: 10)
    link.shipping_destinations << sd
    link.is_physical = true
    link.require_shipping = true
    link.save!(validate: false)

    [Compliance::Countries::USA, Compliance::Countries::DEU, Compliance::Countries::ESP, Compliance::Countries::GBR].each do |c|
      assert_equal sd, ShippingDestination.for_product_and_country_code(product: link, country_code: c.alpha2)
    end
  end

  test "returns a match for the specific country before matching ELSEWHERE" do
    link = make_link
    sd1 = ShippingDestination.new(country_code: ShippingDestination::Destinations::ELSEWHERE, one_item_rate_cents: 20, multiple_items_rate_cents: 10)
    sd2 = ShippingDestination.new(country_code: Compliance::Countries::DEU.alpha2, one_item_rate_cents: 10, multiple_items_rate_cents: 5)
    link.shipping_destinations << sd1 << sd2
    link.is_physical = true
    link.require_shipping = true
    link.save!(validate: false)

    assert_equal sd2, ShippingDestination.for_product_and_country_code(product: link, country_code: Compliance::Countries::DEU.alpha2)
    assert_equal sd1, ShippingDestination.for_product_and_country_code(product: link, country_code: Compliance::Countries::USA.alpha2)
  end

  test "returns a match for a virtual country" do
    link = make_link
    sd1 = ShippingDestination.new(country_code: ShippingDestination::Destinations::EUROPE, one_item_rate_cents: 20, multiple_items_rate_cents: 10, is_virtual_country: true)
    sd2 = ShippingDestination.new(country_code: ShippingDestination::Destinations::ASIA, one_item_rate_cents: 10, multiple_items_rate_cents: 5, is_virtual_country: true)
    sd3 = ShippingDestination.new(country_code: ShippingDestination::Destinations::NORTH_AMERICA, one_item_rate_cents: 10, multiple_items_rate_cents: 5, is_virtual_country: true)
    link.is_physical = true
    link.require_shipping = true
    link.shipping_destinations << sd1 << sd2 << sd3
    link.save!(validate: false)

    assert_equal sd1, ShippingDestination.for_product_and_country_code(product: link, country_code: Compliance::Countries::ESP.alpha2)
    assert_equal sd2, ShippingDestination.for_product_and_country_code(product: link, country_code: Compliance::Countries::IND.alpha2)
    assert_equal sd3, ShippingDestination.for_product_and_country_code(product: link, country_code: Compliance::Countries::USA.alpha2)
    assert_nil ShippingDestination.for_product_and_country_code(product: link, country_code: Compliance::Countries::NGA.alpha2)
  end

  test "returns a country match before a virtual country match" do
    link = make_link
    sd1 = ShippingDestination.new(country_code: Compliance::Countries::USA.alpha2, one_item_rate_cents: 20, multiple_items_rate_cents: 10)
    sd2 = ShippingDestination.new(country_code: ShippingDestination::Destinations::NORTH_AMERICA, one_item_rate_cents: 10, multiple_items_rate_cents: 5, is_virtual_country: true)
    link.shipping_destinations << sd1 << sd2
    link.is_physical = true
    link.require_shipping = true
    link.save!(validate: false)

    assert_equal sd1, ShippingDestination.for_product_and_country_code(product: link, country_code: Compliance::Countries::USA.alpha2)
    assert_equal sd2, ShippingDestination.for_product_and_country_code(product: link, country_code: Compliance::Countries::MEX.alpha2)
  end

  test "returns a match for a virtual country before matching ELSEWHERE" do
    link = make_link
    sd1 = ShippingDestination.new(country_code: ShippingDestination::Destinations::ELSEWHERE, one_item_rate_cents: 20, multiple_items_rate_cents: 10)
    sd2 = ShippingDestination.new(country_code: ShippingDestination::Destinations::NORTH_AMERICA, one_item_rate_cents: 10, multiple_items_rate_cents: 5, is_virtual_country: true)
    link.shipping_destinations << sd1 << sd2
    link.is_physical = true
    link.require_shipping = true
    link.save!(validate: false)

    assert_equal sd2, ShippingDestination.for_product_and_country_code(product: link, country_code: Compliance::Countries::USA.alpha2)
    assert_equal sd1, ShippingDestination.for_product_and_country_code(product: link, country_code: Compliance::Countries::ESP.alpha2)
    assert_equal sd1, ShippingDestination.for_product_and_country_code(product: link, country_code: Compliance::Countries::GBR.alpha2)
  end
end
