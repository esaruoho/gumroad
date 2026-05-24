# frozen_string_literal: true

require "test_helper"

class UtmLinkDrivenSaleTest < ActiveSupport::TestCase
  setup do
    @utm_link = utm_links(:utm_link_for_named_seller)
    @visit = utm_link_visits(:visit_one)
    @purchase = purchases(:auto_invoice_enabled_purchase)
  end

  test "belongs_to utm_link, utm_link_visit, purchase (required)" do
    [:utm_link, :utm_link_visit, :purchase].each do |name|
      reflection = UtmLinkDrivenSale.reflect_on_association(name)
      assert_equal :belongs_to, reflection.macro, "#{name} should be belongs_to"
      assert_not reflection.options[:optional], "#{name} should be required"
    end

    sale = UtmLinkDrivenSale.new
    assert_not sale.valid?
    assert sale.errors[:utm_link].any?
    assert sale.errors[:utm_link_visit].any?
    assert sale.errors[:purchase].any?
  end

  test "validates uniqueness of purchase_id scoped to utm_link_visit_id" do
    UtmLinkDrivenSale.create!(utm_link: @utm_link, utm_link_visit: @visit, purchase: @purchase)
    dup = UtmLinkDrivenSale.new(utm_link: @utm_link, utm_link_visit: @visit, purchase: @purchase)
    assert_not dup.valid?
    assert dup.errors[:purchase_id].any?

    # Different visit, same purchase => allowed
    other_sale = UtmLinkDrivenSale.new(
      utm_link: @utm_link,
      utm_link_visit: utm_link_visits(:visit_two),
      purchase: @purchase
    )
    assert other_sale.valid?
  end
end
