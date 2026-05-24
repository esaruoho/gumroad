# frozen_string_literal: true

require "test_helper"

class CreatorAnalytics::Churn::ProductScopeTest < ActiveSupport::TestCase
  setup do
    @seller = User.new(email: "ps-#{SecureRandom.hex(4)}@example.com", timezone: "UTC")
    @seller.save!(validate: false)
  end

  def build_link(native_type:, flags: 0, name: "Product #{SecureRandom.hex(2)}")
    link = Link.new(
      user: @seller,
      name: name,
      unique_permalink: ("ps" + SecureRandom.hex(3).gsub(/[^a-z]/, "a"))[0, 8],
      price_cents: 100,
      native_type: native_type,
      filetype: "link",
      filegroup: "url"
    )
    link.flags = flags
    link.save!(validate: false)
    link.save! if link.external_id.blank?  # populate external_id via callback
    link
  end

  def add_successful_purchase(link)
    p = Purchase.new(
      link: link,
      seller: @seller,
      email: "buyer-#{SecureRandom.hex(2)}@example.com",
      purchase_state: "successful",
      total_transaction_cents: 100,
      displayed_price_cents: 100,
      displayed_price_currency_type: "usd"
    )
    cols = p.attributes.compact.merge("created_at" => Time.current, "updated_at" => Time.current)
    cols.delete("id")
    Purchase.insert(cols)
  end

  def recurring_bit
    Link.flag_mapping["flags"][:is_recurring_billing]
  end

  def tiered_bit
    Link.flag_mapping["flags"][:is_tiered_membership]
  end

  test "#subscription_products returns only recurring billing and tiered membership products" do
    recurring = build_link(native_type: "membership", flags: recurring_bit)
    tiered = build_link(native_type: "membership", flags: recurring_bit | tiered_bit)
    regular = build_link(native_type: "digital")
    [recurring, tiered, regular].each { |l| add_successful_purchase(l) }

    service = CreatorAnalytics::Churn::ProductScope.new(seller: @seller)
    products = service.subscription_products
    assert_includes products, recurring
    assert_includes products, tiered
    refute_includes products, regular
  end

  test "#subscription_products memoizes the result" do
    build_link(native_type: "membership", flags: recurring_bit)
    service = CreatorAnalytics::Churn::ProductScope.new(seller: @seller)
    calls = 0
    seller = @seller
    seller.define_singleton_method(:products_for_creator_analytics) do
      calls += 1
      seller.links.where(id: seller.links.pluck(:id))
    end
    service.instance_variable_set(:@__seller, seller)
    # Re-init service against this seller instance
    service2 = CreatorAnalytics::Churn::ProductScope.new(seller: seller)
    service2.subscription_products
    service2.subscription_products
    assert_equal 1, calls
  end

  test "#product_map returns a hash mapping product id to product info" do
    recurring = build_link(native_type: "membership", flags: recurring_bit, name: "Recurring Product")
    tiered = build_link(native_type: "membership", flags: recurring_bit | tiered_bit, name: "Tiered Product")
    [recurring, tiered].each { |l| add_successful_purchase(l) }

    service = CreatorAnalytics::Churn::ProductScope.new(seller: @seller)
    map = service.product_map
    assert_kind_of Hash, map
    assert_equal({
      id: recurring.id,
      external_id: recurring.external_id,
      permalink: recurring.unique_permalink,
      name: "Recurring Product"
    }, map[recurring.id])
    assert_equal({
      id: tiered.id,
      external_id: tiered.external_id,
      permalink: tiered.unique_permalink,
      name: "Tiered Product"
    }, map[tiered.id])
  end

  test "#earliest_analytics_date returns the first sale date in seller's timezone" do
    first_sale_time = Time.utc(2020, 1, 15, 10, 30)
    product = build_link(native_type: "digital")
    add_successful_purchase(product)
    Purchase.where(link_id: product.id).update_all(created_at: first_sale_time)

    service = CreatorAnalytics::Churn::ProductScope.new(seller: @seller)
    assert_equal first_sale_time.in_time_zone(@seller.timezone).to_date, service.earliest_analytics_date
  end

  test "#earliest_analytics_date falls back to seller created_at when no sales" do
    @seller.update_columns(created_at: Time.utc(2020, 1, 1, 12, 0))
    service = CreatorAnalytics::Churn::ProductScope.new(seller: @seller)
    assert_equal Time.utc(2020, 1, 1, 12, 0).in_time_zone(@seller.timezone).to_date,
                 service.earliest_analytics_date
  end

  test "#earliest_analytics_date in Pacific timezone uses seller's timezone" do
    @seller.update!(timezone: "Pacific Time (US & Canada)")
    product = build_link(native_type: "digital")
    add_successful_purchase(product)
    Purchase.where(link_id: product.id).update_all(created_at: Time.utc(2020, 1, 15, 8, 0))

    service = CreatorAnalytics::Churn::ProductScope.new(seller: @seller)
    assert_equal Time.utc(2020, 1, 15, 8, 0).in_time_zone(@seller.timezone).to_date,
                 service.earliest_analytics_date
  end

  test "#first_sale_date returns nil when seller has no sales" do
    service = CreatorAnalytics::Churn::ProductScope.new(seller: @seller)
    assert_nil service.first_sale_date
  end

  test "#first_sale_date returns the earliest sale date across multiple sales" do
    earliest = Time.utc(2020, 1, 10, 10, 0)
    later = Time.utc(2020, 1, 20, 10, 0)
    p1 = build_link(native_type: "digital")
    p2 = build_link(native_type: "digital")
    add_successful_purchase(p1)
    add_successful_purchase(p2)
    Purchase.where(link_id: p1.id).update_all(created_at: later)
    Purchase.where(link_id: p2.id).update_all(created_at: earliest)

    service = CreatorAnalytics::Churn::ProductScope.new(seller: @seller)
    assert_equal earliest.in_time_zone(@seller.timezone).to_date, service.first_sale_date
  end
end
