# frozen_string_literal: true

require "test_helper"

# Migrated from spec/helpers/products_helper_spec.rb (deleted in c9c93ee5).
# The full original spec covered AS-attachment previews (Link#preview via
# fixture_file_upload) and Elasticsearch `sort_and_paginate_products`
# behaviour. We keep the deterministic helper-method assertions and rely on
# `cdn_url_for` being exercised by a stub for CDN_URL_MAP (which the prod
# initializer leaves empty in non-prod envs).
class ProductsHelperTest < ActionView::TestCase
  include ProductsHelper

  setup do
    @product = links(:named_seller_product)
  end

  # --- view_content_button_text --------------------------------------------
  test "view_content_button_text shows custom text when set" do
    @product.update!(custom_view_content_button_text: "Custom Text")
    refute_nil @product.custom_view_content_button_text
    assert_equal "Custom Text", view_content_button_text(@product)
  end

  test "view_content_button_text falls back to default" do
    @product.update!(custom_view_content_button_text: nil)
    assert_nil @product.custom_view_content_button_text
    assert_equal "View content", view_content_button_text(@product)
  end

  # --- variant_names_displayable -------------------------------------------
  test "variant_names_displayable returns nil for empty array" do
    assert_nil variant_names_displayable([])
  end

  test "variant_names_displayable returns nil for only Untitled" do
    assert_nil variant_names_displayable(["Untitled"])
  end

  test "variant_names_displayable joins multiple names" do
    assert_equal "name1, name2", variant_names_displayable(%w[name1 name2])
  end

  # --- cdn_url_for ---------------------------------------------------------
  # cdn_url_for is just CDN_URL_MAP-driven gsub. Stub CDN_URL_MAP directly
  # for the duration of the test rather than relying on Active Storage to
  # produce real preview URLs (which the original spec did via fixture_file_upload).
  test "cdn_url_for rewrites gumroad-specs bucket URL" do
    map = {
      "#{AWS_S3_ENDPOINT}/gumroad/" => "https://asset.host.example.com/res/gumroad/",
      "#{AWS_S3_ENDPOINT}/gumroad-staging/" => "https://asset.host.example.com/res/gumroad-staging/",
      "#{AWS_S3_ENDPOINT}/#{S3_BUCKET}/" => "https://asset.host.example.com/res/gumroad-specs/",
    }
    with_cdn_url_map(map) do
      url = "#{AWS_S3_ENDPOINT}/#{S3_BUCKET}/abc/def.png"
      expected = "https://asset.host.example.com/res/gumroad-specs/abc/def.png"
      assert_equal expected, cdn_url_for(url)
    end
  end

  test "cdn_url_for rewrites gumroad-staging bucket URL" do
    map = {
      "#{AWS_S3_ENDPOINT}/gumroad-staging/" => "https://asset.host.example.com/res/gumroad-staging/",
    }
    with_cdn_url_map(map) do
      url = "#{AWS_S3_ENDPOINT}/gumroad-staging/img.png"
      assert_equal "https://asset.host.example.com/res/gumroad-staging/img.png", cdn_url_for(url)
    end
  end

  test "cdn_url_for leaves unrelated S3 URLs untouched" do
    map = {
      "#{AWS_S3_ENDPOINT}/gumroad/" => "https://asset.host.example.com/res/gumroad/",
    }
    with_cdn_url_map(map) do
      url = "#{AWS_S3_ENDPOINT}/gumroad_other/img.png"
      assert_equal url, cdn_url_for(url)
    end
  end

  test "cdn_url_for returns empty string for empty input" do
    assert_equal "", cdn_url_for("")
  end

  # --- url_for_product_page ------------------------------------------------
  test "url_for_product_page returns long_url when request is nil" do
    expected = @product.long_url(recommended_by: "test")
    assert_equal expected, url_for_product_page(@product, request: nil, recommended_by: "test")
  end

  test "url_for_product_page returns long_url when request host is DOMAIN" do
    request = OpenStruct.new(host: DOMAIN, host_with_port: "#{DOMAIN}:3000", protocol: "http://")
    expected = @product.long_url(recommended_by: "test")
    assert_equal expected, url_for_product_page(@product, request: request, recommended_by: "test")
  end

  test "url_for_product_page returns long_url with offer_code" do
    expected = @product.long_url(recommended_by: "test", code: "BLACKFRIDAY2025")
    assert_equal expected, url_for_product_page(@product, request: nil, recommended_by: "test", offer_code: "BLACKFRIDAY2025")
  end

  test "url_for_product_page returns relative short_link_url when host matches user's subdomain" do
    host = @product.user.subdomain
    # `request` here is the test's @request — set its host then call the helper
    # via the controller infrastructure (host_with_port + protocol needed too).
    fake_request = OpenStruct.new(host: host, host_with_port: host, protocol: "http://")
    result = url_for_product_page(@product, request: fake_request, recommended_by: "test")
    assert_includes result, "/l/#{@product.general_permalink}"
    assert_includes result, "recommended_by=test"
  end

  test "url_for_product_page returns relative short_link_url without recommended_by when blank" do
    host = @product.user.subdomain
    fake_request = OpenStruct.new(host: host, host_with_port: host, protocol: "http://")
    result = url_for_product_page(@product, request: fake_request, recommended_by: "")
    assert_includes result, "/l/#{@product.general_permalink}"
    refute_includes result, "recommended_by"
  end

  test "url_for_product_page returns long_url when on a different user's subdomain" do
    other = users(:basic_user)
    fake_request = OpenStruct.new(host: other.subdomain, host_with_port: other.subdomain, protocol: "http://")
    result = url_for_product_page(@product, request: fake_request, recommended_by: "test")
    assert_equal @product.long_url(recommended_by: "test"), result
  end

  private
    def with_cdn_url_map(map)
      original = CDN_URL_MAP.dup
      CDN_URL_MAP.clear
      CDN_URL_MAP.merge!(map)
      yield
    ensure
      CDN_URL_MAP.clear
      CDN_URL_MAP.merge!(original)
    end
end
