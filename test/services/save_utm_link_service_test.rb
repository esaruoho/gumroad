# frozen_string_literal: true

require "test_helper"

class SaveUtmLinkServiceTest < ActiveSupport::TestCase
  setup do
    @seller = users(:named_seller)
    @product = links(:named_seller_product)
    @post = installments(:published_post)
  end

  test "creates a UTM link for a product page" do
    assert_difference -> { @seller.utm_links.count }, 1 do
      SaveUtmLinkService.new(
        seller: @seller,
        params: {
          title: "Test Link",
          target_resource_id: @product.external_id,
          target_resource_type: "product_page",
          permalink: "abc12345",
          utm_source: "facebook",
          utm_medium: "social",
          utm_campaign: "summer",
          utm_term: "sale",
          utm_content: "banner",
          ip_address: "192.168.1.1",
          browser_guid: "1234567890"
        }
      ).perform
    end

    utm_link = @seller.utm_links.last
    assert_equal "Test Link", utm_link.title
    assert_equal "product_page", utm_link.target_resource_type
    assert_equal @product.id, utm_link.target_resource_id
    assert_equal "abc12345", utm_link.permalink
    assert_equal "facebook", utm_link.utm_source
    assert_equal "social", utm_link.utm_medium
    assert_equal "summer", utm_link.utm_campaign
    assert_equal "sale", utm_link.utm_term
    assert_equal "banner", utm_link.utm_content
    assert_equal "192.168.1.1", utm_link.ip_address
    assert_equal "1234567890", utm_link.browser_guid
  end

  test "creates a UTM link for a post page" do
    assert_difference -> { @seller.utm_links.count }, 1 do
      SaveUtmLinkService.new(
        seller: @seller,
        params: {
          title: "Test Link",
          target_resource_id: @post.external_id,
          target_resource_type: "post_page",
          permalink: "abc12345",
          utm_source: "twitter",
          utm_medium: "social",
          utm_campaign: "winter"
        }
      ).perform
    end

    utm_link = @seller.utm_links.last
    assert_equal "Test Link", utm_link.title
    assert_equal "post_page", utm_link.target_resource_type
    assert_equal @post.id, utm_link.target_resource_id
    assert_equal "abc12345", utm_link.permalink
    assert_equal "twitter", utm_link.utm_source
    assert_equal "social", utm_link.utm_medium
    assert_equal "winter", utm_link.utm_campaign
    assert_nil utm_link.utm_term
    assert_nil utm_link.utm_content
  end

  test "creates a UTM link for the profile page" do
    assert_difference -> { @seller.utm_links.count }, 1 do
      SaveUtmLinkService.new(
        seller: @seller,
        params: {
          title: "Test Link",
          target_resource_id: nil,
          target_resource_type: "profile_page",
          permalink: "abc12345",
          utm_source: "instagram",
          utm_medium: "social",
          utm_campaign: "spring"
        }
      ).perform
    end

    utm_link = @seller.utm_links.last
    assert_equal "profile_page", utm_link.target_resource_type
    assert_nil utm_link.target_resource_id
    assert_equal "instagram", utm_link.utm_source
  end

  test "creates a UTM link for the subscribe page" do
    assert_difference -> { @seller.utm_links.count }, 1 do
      SaveUtmLinkService.new(
        seller: @seller,
        params: {
          title: "Test Link",
          target_resource_type: "subscribe_page",
          permalink: "abc12345",
          utm_source: "newsletter",
          utm_medium: "email",
          utm_campaign: "subscribe"
        }
      ).perform
    end

    utm_link = @seller.utm_links.last
    assert_equal "subscribe_page", utm_link.target_resource_type
    assert_nil utm_link.target_resource_id
    assert_equal "newsletter", utm_link.utm_source
  end

  test "raises an error if the UTM link fails to save (create)" do
    err = assert_raises(ActiveRecord::RecordInvalid) do
      SaveUtmLinkService.new(
        seller: @seller,
        params: {
          title: "Test Link",
          target_resource_type: "product_page",
          target_resource_id: @product.external_id,
          permalink: "abc",
          utm_source: "facebook",
          utm_medium: "social",
          utm_campaign: "summer",
        }
      ).perform
    end
    assert_equal "Validation failed: Permalink is invalid", err.message
  end

  test "updates only the permitted attributes when utm_link is provided" do
    utm_link = @seller.utm_links.create!(
      title: "Existing",
      target_resource_type: "profile_page",
      permalink: "zzzz9999",
      utm_source: "old",
      utm_medium: "old",
      utm_campaign: "old",
      ip_address: "192.168.1.1",
      browser_guid: "1234567890"
    )
    old_permalink = utm_link.permalink

    SaveUtmLinkService.new(
      seller: @seller,
      params: {
        title: "Updated Title",
        target_resource_id: @product.external_id,
        target_resource_type: "product_page",
        permalink: "abc12345",
        utm_source: "facebook",
        utm_medium: "social",
        utm_campaign: "summer",
        utm_term: "sale",
        utm_content: "banner",
        ip_address: "172.0.0.1",
        browser_guid: "9876543210"
      },
      utm_link:
    ).perform

    utm_link.reload
    assert_equal "Updated Title", utm_link.title
    assert_nil utm_link.target_resource_id
    assert_equal "profile_page", utm_link.target_resource_type
    assert_equal old_permalink, utm_link.permalink
    assert_equal "facebook", utm_link.utm_source
    assert_equal "social", utm_link.utm_medium
    assert_equal "summer", utm_link.utm_campaign
    assert_equal "sale", utm_link.utm_term
    assert_equal "banner", utm_link.utm_content
    assert_equal "192.168.1.1", utm_link.ip_address
    assert_equal "1234567890", utm_link.browser_guid
  end

  test "raises an error if the UTM link fails to save (update)" do
    utm_link = @seller.utm_links.create!(
      title: "Existing",
      target_resource_type: "profile_page",
      permalink: "zzzz9998",
      utm_source: "old",
      utm_medium: "old",
      utm_campaign: "old"
    )

    err = assert_raises(ActiveRecord::RecordInvalid) do
      SaveUtmLinkService.new(
        seller: @seller,
        params: {
          title: "Updated Title",
          utm_source: "a" * 256,
          utm_medium: "social",
          utm_campaign: "summer",
        },
        utm_link:
      ).perform
    end
    assert_equal "Validation failed: Utm source is too long (maximum is 200 characters)", err.message
  end
end
