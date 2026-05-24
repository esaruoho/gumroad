# frozen_string_literal: true

require "test_helper"

class WidgetPresenterTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options
    { host: DOMAIN, protocol: PROTOCOL }
  end

  setup do
    @demo_product = links(:widget_demo_product)
  end

  # -- when user is not signed in --------------------------------------------
  test "without seller returns the demo product" do
    presenter = WidgetPresenter.new(seller: nil)
    assert_equal(
      {
        display_product_select: false,
        default_product: {
          name: "The Works of Edgar Gumstein",
          url: @demo_product.long_url,
          gumroad_domain_url: @demo_product.long_url,
          script_base_url: UrlService.root_domain_with_protocol
        },
        products: [
          {
            name: "The Works of Edgar Gumstein",
            url: @demo_product.long_url,
            gumroad_domain_url: @demo_product.long_url,
            script_base_url: UrlService.root_domain_with_protocol
          }
        ],
        affiliated_products: []
      },
      presenter.widget_props
    )
  end

  # -- signed-in user without own products -----------------------------------
  test "signed-in user without products returns the demo product" do
    user = users(:widget_lonely_user)
    presenter = WidgetPresenter.new(seller: user)

    assert_equal(
      {
        display_product_select: true,
        default_product: {
          name: "The Works of Edgar Gumstein",
          url: @demo_product.long_url,
          gumroad_domain_url: @demo_product.long_url,
          script_base_url: UrlService.root_domain_with_protocol
        },
        products: [
          {
            name: "The Works of Edgar Gumstein",
            url: @demo_product.long_url,
            gumroad_domain_url: @demo_product.long_url,
            script_base_url: UrlService.root_domain_with_protocol
          }
        ],
        affiliated_products: []
      },
      presenter.widget_props
    )
  end

  # -- signed-in user with own products --------------------------------------
  test "signed-in user with own products returns those products" do
    user = users(:widget_single_product_owner)
    product = links(:widget_single_product)
    presenter = WidgetPresenter.new(seller: user)

    assert_equal(
      {
        display_product_select: true,
        default_product: {
          name: product.name,
          url: product.long_url,
          gumroad_domain_url: product.long_url,
          script_base_url: UrlService.root_domain_with_protocol
        },
        products: [
          {
            name: product.name,
            url: product.long_url,
            gumroad_domain_url: product.long_url,
            script_base_url: UrlService.root_domain_with_protocol
          }
        ],
        affiliated_products: []
      },
      presenter.widget_props
    )
  end

  # -- signed-in user with affiliated products -------------------------------
  test "signed-in user with affiliated products returns demo + affiliated" do
    user = users(:widget_affiliate_user)
    affiliate_product = links(:widget_affiliate_product)
    direct_affiliate = affiliates(:widget_user_direct_affiliate)
    presenter = WidgetPresenter.new(seller: user)

    assert_equal(
      {
        display_product_select: true,
        default_product: {
          name: @demo_product.name,
          url: @demo_product.long_url,
          gumroad_domain_url: @demo_product.long_url,
          script_base_url: UrlService.root_domain_with_protocol
        },
        products: [
          {
            name: @demo_product.name,
            url: @demo_product.long_url,
            gumroad_domain_url: @demo_product.long_url,
            script_base_url: UrlService.root_domain_with_protocol
          }
        ],
        affiliated_products: [
          {
            name: affiliate_product.name,
            url: affiliate_product_url(affiliate_id: direct_affiliate.external_id_numeric,
                                       unique_permalink: affiliate_product.unique_permalink,
                                       host: UrlService.root_domain_with_protocol),
            gumroad_domain_url: affiliate_product_url(affiliate_id: direct_affiliate.external_id_numeric,
                                                     unique_permalink: affiliate_product.unique_permalink,
                                                     host: UrlService.root_domain_with_protocol),
            script_base_url: UrlService.root_domain_with_protocol
          }
        ]
      },
      presenter.widget_props
    )
  end

  # -- multi-product user ----------------------------------------------------
  test "with product argument uses it as default_product" do
    user = users(:widget_multi_owner)
    new_product = links(:widget_multi_new_product)
    old_product = links(:widget_multi_old_product)
    presenter = WidgetPresenter.new(seller: user, product: old_product)

    assert_equal(
      {
        display_product_select: false,
        default_product: {
          name: "Old Product",
          url: old_product.long_url,
          gumroad_domain_url: old_product.long_url,
          script_base_url: UrlService.root_domain_with_protocol
        },
        products: [
          {
            name: "New Product",
            url: new_product.long_url,
            gumroad_domain_url: new_product.long_url,
            script_base_url: UrlService.root_domain_with_protocol
          },
          {
            name: "Old Product",
            url: old_product.long_url,
            gumroad_domain_url: old_product.long_url,
            script_base_url: UrlService.root_domain_with_protocol
          }
        ],
        affiliated_products: []
      },
      presenter.widget_props
    )
  end

  test "without product argument default_product is newest product" do
    user = users(:widget_multi_owner)
    new_product = links(:widget_multi_new_product)
    old_product = links(:widget_multi_old_product)
    presenter = WidgetPresenter.new(seller: user)

    assert_equal(
      {
        display_product_select: true,
        default_product: {
          name: "New Product",
          url: new_product.long_url,
          gumroad_domain_url: new_product.long_url,
          script_base_url: UrlService.root_domain_with_protocol
        },
        products: [
          {
            name: "New Product",
            url: new_product.long_url,
            gumroad_domain_url: new_product.long_url,
            script_base_url: UrlService.root_domain_with_protocol
          },
          {
            name: "Old Product",
            url: old_product.long_url,
            gumroad_domain_url: old_product.long_url,
            script_base_url: UrlService.root_domain_with_protocol
          }
        ],
        affiliated_products: []
      },
      presenter.widget_props
    )
  end
end
