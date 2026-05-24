# frozen_string_literal: true

require "test_helper"

class ThirdPartyAnalyticTest < ActiveSupport::TestCase
  setup do
    @user = users(:named_seller)
    @product = links(:named_seller_product)
  end

  # ---- #save_third_party_analytics (new analytics) ----

  test "creates a new third_party_analytic for creator" do
    params = [{
      name: "Snippet 1",
      location: "product",
      product: "#all_products",
      code: "<span>The first analytics</span>",
    }]

    result = ThirdPartyAnalytic.save_third_party_analytics(params, @user)
    assert_equal [ThirdPartyAnalytic.last.external_id], result
    assert_equal 1, @user.third_party_analytics.count
    assert_equal "Snippet 1", @user.third_party_analytics.first.name
    assert_equal "product", @user.third_party_analytics.first.location
    assert_equal "<span>The first analytics</span>", @user.third_party_analytics.first.analytics_code
    assert_equal 0, @product.third_party_analytics.count
  end

  test "creates a new third_party_analytic for product" do
    params = [{
      name: "Snippet 1",
      location: "product",
      product: @product.unique_permalink,
      code: "<span>The first analytics</span>",
    }]

    result = ThirdPartyAnalytic.save_third_party_analytics(params, @user)
    assert_equal [ThirdPartyAnalytic.last.external_id], result
    assert_equal 1, @product.third_party_analytics.count
    assert_equal "Snippet 1", @user.third_party_analytics.first.name
    assert_equal "product", @user.third_party_analytics.first.location
    assert_equal "<span>The first analytics</span>", @product.third_party_analytics.first.analytics_code
    assert_equal 1, @user.third_party_analytics.count
  end

  test "rejects two snippets with the same location for the same user" do
    params = [
      { name: "Snippet 1", location: "product", product: "#all_products", code: "<span>1</span>" },
      { name: "Snippet 2", location: "product", product: "#all_products", code: "<span>2</span>" },
    ]
    assert_raises(ThirdPartyAnalytic::ThirdPartyAnalyticInvalid) do
      ThirdPartyAnalytic.save_third_party_analytics(params, @user)
    end
    assert_equal 0, ThirdPartyAnalytic.count
  end

  test "rejects two snippets with the same location for the same product" do
    params = [
      { name: "Snippet 1", location: "product", product: @product.unique_permalink, code: "<span>1</span>" },
      { name: "Snippet 2", location: "product", product: @product.unique_permalink, code: "<span>2</span>" },
    ]
    assert_raises(ThirdPartyAnalytic::ThirdPartyAnalyticInvalid) do
      ThirdPartyAnalytic.save_third_party_analytics(params, @user)
    end
    assert_equal 0, ThirdPartyAnalytic.count
  end

  test "allows two snippets with different locations for the same user" do
    params = [
      { name: "Snippet 1", location: "product", product: "#all_products", code: "<span>1</span>" },
      { name: "Snippet 2", location: "all", product: "#all_products", code: "<span>2</span>" },
    ]
    result = ThirdPartyAnalytic.save_third_party_analytics(params, @user)
    assert_equal [ThirdPartyAnalytic.second_to_last.external_id, ThirdPartyAnalytic.last.external_id], result
    assert_equal 2, ThirdPartyAnalytic.count
  end

  test "allows two snippets with different locations for the same product" do
    params = [
      { name: "Snippet 1", location: "product", product: @product.unique_permalink, code: "<span>1</span>" },
      { name: "Snippet 2", location: "receipt", product: @product.unique_permalink, code: "<span>2</span>" },
    ]
    result = ThirdPartyAnalytic.save_third_party_analytics(params, @user)
    assert_equal [ThirdPartyAnalytic.second_to_last.external_id, ThirdPartyAnalytic.last.external_id], result
    assert_equal 2, ThirdPartyAnalytic.count
  end

  # ---- existing analytics ----

  test "updates an existing third_party_analytic for creator" do
    tpa = @user.third_party_analytics.create!(
      analytics_code: "<span>old</span>", name: "Old", location: "product", link: nil
    )

    params = [{
      id: tpa.external_id,
      name: "Snippet 1",
      location: "product",
      product: "#all_products",
      code: "HERE COMES THE PARTY",
    }]

    assert_equal [tpa.external_id], ThirdPartyAnalytic.save_third_party_analytics(params, @user)
    tpa.reload
    assert_equal 1, @user.third_party_analytics.count
    assert_equal "Snippet 1", tpa.name
    assert_equal "product", tpa.location
    assert_equal "HERE COMES THE PARTY", tpa.analytics_code
    assert_equal 0, @product.third_party_analytics.count
  end

  test "updates an existing third_party_analytic for product" do
    tpa = @user.third_party_analytics.create!(
      analytics_code: "<span>old</span>", name: "Old", location: "product", link: @product
    )

    params = [{
      id: tpa.external_id,
      name: "Snippet 1",
      location: "product",
      product: @product.unique_permalink,
      code: "HERE COMES THE PARTY!",
    }]

    assert_equal [tpa.external_id], ThirdPartyAnalytic.save_third_party_analytics(params, @user)
    tpa.reload
    assert_equal 1, @product.third_party_analytics.count
    assert_equal "Snippet 1", tpa.name
    assert_equal "product", tpa.location
    assert_equal "HERE COMES THE PARTY!", tpa.analytics_code
    assert_equal 1, @user.third_party_analytics.count
  end

  test "deletes user's third_party_analytics when given empty params" do
    @user.third_party_analytics.create!(
      analytics_code: "<span>old</span>", name: "Old", location: "product", link: nil
    )
    assert_equal [], ThirdPartyAnalytic.save_third_party_analytics({}, @user)
    assert_equal 0, @user.third_party_analytics.alive.count
  end

  # ---- #clear_related_products_cache ----

  test "calls clear_products_cache on the user when saved" do
    tpa = @user.third_party_analytics.create!(
      analytics_code: "<span>x</span>", name: "n", location: "product", link: @product
    )
    called = 0
    captured_user = tpa.user
    captured_user.define_singleton_method(:clear_products_cache) { called += 1 }
    tpa.define_singleton_method(:user) { captured_user }
    tpa.clear_related_products_cache
    assert_equal 1, called
  end
end
