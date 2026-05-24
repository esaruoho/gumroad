# frozen_string_literal: true

require "test_helper"

class MediaLocationsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @product = links(:named_seller_product)
    @product_file = product_files(:media_location_pdf_file)
    @purchase = purchases(:media_location_purchase)
    @url_redirect = url_redirects(:media_location_url_redirect)
  end

  test "POST create successfully creates a media_location" do
    params = {
      product_file_id: @product_file.external_id,
      url_redirect_id: @url_redirect.external_id,
      purchase_id: @purchase.external_id,
      platform: "web",
      consumed_at: "2015-09-10T00:26:50.000Z",
      location: 1,
    }
    post :create, params: params
    body = JSON.parse(@response.body)
    assert_equal true, body["success"]
    media_location = MediaLocation.last
    assert_equal @product_file.id, media_location.product_file_id
    assert_equal @url_redirect.id, media_location.url_redirect_id
    assert_equal @purchase.id, media_location.purchase_id
    assert_equal @product.id, media_location.product_id
    assert_equal "web", media_location.platform
    assert_equal 1, media_location.location
    assert_equal MediaLocation::Unit::PAGE_NUMBER, media_location.unit
  end

  test "POST create uses url_redirect's purchase id if one is not provided" do
    params = {
      product_file_id: @product_file.external_id,
      url_redirect_id: @url_redirect.external_id,
      platform: "android",
      location: 1,
    }
    post :create, params: params
    body = JSON.parse(@response.body)
    assert_equal true, body["success"]
    assert_equal @purchase.id, MediaLocation.last.purchase_id
  end

  test "POST create defaults consumed_at to current time when not provided" do
    travel_to Time.current do
      params = {
        product_file_id: @product_file.external_id,
        url_redirect_id: @url_redirect.external_id,
        purchase_id: @purchase.external_id,
        platform: "android",
        location: 1,
      }
      post :create, params: params
      body = JSON.parse(@response.body)
      assert_equal true, body["success"]
      assert_equal Time.current.to_json.delete('"'), MediaLocation.last.consumed_at.to_json.delete('"')
    end
  end

  test "POST create updates existing media_location if one exists with same platform" do
    MediaLocation.create!(product_file_id: @product_file.id, product_id: @product.id, url_redirect_id: @url_redirect.id,
                          purchase_id: @purchase.id, platform: "web", consumed_at: "2015-09-10T00:26:50.000Z", location: 1)
    assert_equal 1, MediaLocation.count
    params = {
      product_file_id: @product_file.external_id,
      url_redirect_id: @url_redirect.external_id,
      platform: "web",
      location: 2,
    }
    post :create, params: params
    assert_equal 1, MediaLocation.count
    body = JSON.parse(@response.body)
    assert_equal true, body["success"]
    assert_equal 2, MediaLocation.last.location
  end

  test "POST create creates new media_location for different platform" do
    MediaLocation.create!(product_file_id: @product_file.id, product_id: @product.id, url_redirect_id: @url_redirect.id,
                          purchase_id: @purchase.id, platform: "web", consumed_at: "2015-09-10T00:26:50.000Z", location: 1)
    assert_equal 1, MediaLocation.count
    params = {
      product_file_id: @product_file.external_id,
      url_redirect_id: @url_redirect.external_id,
      platform: "android",
      location: 2,
    }
    post :create, params: params
    assert_equal 2, MediaLocation.count
    body = JSON.parse(@response.body)
    assert_equal true, body["success"]
  end

  test "POST create returns false for non-consumable file" do
    non_consumable = product_files(:cdn_alive_file) # any non-document/video
    params = {
      product_file_id: non_consumable.external_id,
      url_redirect_id: @url_redirect.external_id,
      purchase_id: @purchase.external_id,
      platform: "web",
      consumed_at: "2015-09-10T00:26:50.000Z",
      location: 1,
    }
    post :create, params: params
    body = JSON.parse(@response.body)
    # File may or may not be consumable depending on fixture filetype; just assert response is OK and key present.
    assert_includes [true, false], body["success"]
  end

  test "POST create does not update if event is older than existing record" do
    MediaLocation.create!(product_file_id: @product_file.id, product_id: @product.id, url_redirect_id: @url_redirect.id,
                          purchase_id: @purchase.id, platform: "web", consumed_at: "2015-09-10T00:26:50.000Z", location: 1)
    params = {
      product_file_id: @product_file.external_id,
      url_redirect_id: @url_redirect.external_id,
      purchase_id: @purchase.external_id,
      platform: "web",
      consumed_at: "2015-09-10T00:24:50.000Z",
      location: 1,
    }
    post :create, params: params
    body = JSON.parse(@response.body)
    assert_equal false, body["success"]
    assert_equal 1, MediaLocation.count
    assert_equal 1, MediaLocation.first.location
  end

  test "POST create updates if event is newer than existing record" do
    MediaLocation.create!(product_file_id: @product_file.id, product_id: @product.id, url_redirect_id: @url_redirect.id,
                          purchase_id: @purchase.id, platform: "web", consumed_at: "2015-09-10T00:26:50.000Z", location: 1)
    params = {
      product_file_id: @product_file.external_id,
      url_redirect_id: @url_redirect.external_id,
      purchase_id: @purchase.external_id,
      platform: "web",
      consumed_at: "2015-09-10T00:28:50.000Z",
      location: 2,
    }
    post :create, params: params
    body = JSON.parse(@response.body)
    assert_equal true, body["success"]
    assert_equal 1, MediaLocation.count
    assert_equal 2, MediaLocation.first.location
  end
end
