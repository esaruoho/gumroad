# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class DropboxFilesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @admin = users(:admin_for_named_seller)
    @product = links(:named_seller_product)
    sign_in_as_seller(@admin, @seller)
  end

  teardown { restore_protect_against_forgery! }

  def make_file(link: nil)
    DropboxFile.create!(state: "successfully_uploaded", user: @seller, link: link, dropbox_url: "http://example.com/#{SecureRandom.hex(4)}.zip", s3_url: "https://s3.amazonaws.com/gumroad/x.zip")
  end

  test "POST create enqueues the job to transfer the file to S3" do
    Sidekiq::Testing.fake! do
      TransferDropboxFileToS3Worker.jobs.clear
      post :create, params: { link: "http://example.com/dropbox-url" }
      assert_response :success
      assert_equal 1, TransferDropboxFileToS3Worker.jobs.size
      assert_kind_of Integer, TransferDropboxFileToS3Worker.jobs.first["args"].first
    end
  end

  test "GET index returns available files for product" do
    file = make_file(link: @product)
    get :index, params: { link_id: @product.unique_permalink }
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal 1, body["dropbox_files"].length
    assert_equal file.external_id, body["dropbox_files"].first["external_id"]
  end

  test "GET index returns available files for user when no link_id" do
    file = make_file
    get :index
    assert_response :success
    body = JSON.parse(@response.body)
    ids = body["dropbox_files"].map { |f| f["external_id"] }
    assert_includes ids, file.external_id
  end

  test "POST cancel_upload marks an uploaded file deleted" do
    file = make_file(link: @product)
    post :cancel_upload, params: { id: file.external_id }
    assert_response :success
    assert file.reload.deleted_at.present?
  end

  test "POST cancel_upload returns success false for unknown id" do
    post :cancel_upload, params: { id: "nonexistent" }
    body = JSON.parse(@response.body)
    assert_equal false, body["success"]
  end
end
