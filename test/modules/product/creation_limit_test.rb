# frozen_string_literal: true

require "test_helper"

class Product::CreationLimitTest < ActiveSupport::TestCase
  setup do
    @non_compliant = users(:creation_limit_non_compliant)
    @compliant = users(:creation_limit_compliant)
    @custom = users(:creation_limit_custom)
    @higher = users(:creation_limit_higher)
    @team_member = users(:creation_limit_team_member)
  end

  test "for non-compliant users: prevents creating more than 10 products in 24 hours" do
    create_products_in_bulk(@non_compliant, 9)

    product_10 = build_product(@non_compliant)
    assert product_10.valid?, product_10.errors.full_messages.inspect
    product_10.save!

    product_11 = build_product(@non_compliant)
    assert_not product_11.valid?
    assert_includes product_11.errors.full_messages, "Sorry, you can only create 10 products per day."

    travel_to 25.hours.from_now do
      assert build_product(@non_compliant).valid?
    end
  end

  test "for compliant users: allows up to 100 products in 24 hours" do
    create_products_in_bulk(@compliant, 99)

    product_100 = build_product(@compliant)
    assert product_100.valid?
    product_100.save!

    product_101 = build_product(@compliant)
    assert_not product_101.valid?
    assert_includes product_101.errors.full_messages, "Sorry, you can only create 100 products per day."

    travel_to 25.hours.from_now do
      assert build_product(@compliant).valid?
    end
  end

  test "skips daily limit for team members" do
    create_products_in_bulk(@team_member, 100)
    assert build_product(@team_member).valid?
  end

  test "uses the user's custom daily_product_creation_limit when set" do
    create_products_in_bulk(@custom, 4)

    product_5 = build_product(@custom)
    assert product_5.valid?
    product_5.save!

    product_6 = build_product(@custom)
    assert_not product_6.valid?
    assert_includes product_6.errors.full_messages, "Sorry, you can only create 5 products per day."
  end

  test "allows increasing the limit beyond the default for compliant users" do
    create_products_in_bulk(@higher, 100)

    product_101 = build_product(@higher)
    assert product_101.valid?
    product_101.save!

    create_products_in_bulk(@higher, 49)

    product_151 = build_product(@higher)
    assert_not product_151.valid?
    assert_includes product_151.errors.full_messages, "Sorry, you can only create 150 products per day."
  end

  test "falls back to default limit when custom limit is not set" do
    @non_compliant.daily_product_creation_limit = nil
    @non_compliant.save!
    create_products_in_bulk(@non_compliant, 10)

    product_11 = build_product(@non_compliant)
    assert_not product_11.valid?
    assert_includes product_11.errors.full_messages, "Sorry, you can only create 10 products per day."
  end

  test ".bypass_product_creation_limit bypasses the limit within the block and restores it after" do
    create_products_in_bulk(@non_compliant, 10)

    Link.bypass_product_creation_limit do
      assert build_product(@non_compliant).valid?
    end

    blocked = build_product(@non_compliant)
    assert_not blocked.valid?
    assert_includes blocked.errors.full_messages, "Sorry, you can only create 10 products per day."
  end

  private
    def build_product(user)
      Link.new(
        user: user,
        name: "Test product",
        unique_permalink: SecureRandom.alphanumeric(10, chars: ("a".."z").to_a),
        price_cents: 100,
        purchase_type: 0,
        native_type: "digital",
        filetype: "link",
        filegroup: "url",
        discover_fee_per_thousand: 100,
        flags: 0,
      )
    end

    def create_products_in_bulk(user, count)
      now = Time.current
      rows = Array.new(count) do
        {
          user_id: user.id,
          name: "Bulk product",
          unique_permalink: SecureRandom.alphanumeric(10, chars: ("a".."z").to_a),
          price_cents: 100,
          purchase_type: 0,
          native_type: "digital",
          filetype: "link",
          filegroup: "url",
          discover_fee_per_thousand: 100,
          flags: 0,
          created_at: now,
          updated_at: now,
        }
      end
      Link.insert_all(rows)
    end
end
