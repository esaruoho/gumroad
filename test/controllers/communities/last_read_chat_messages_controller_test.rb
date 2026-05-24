# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

class Communities::LastReadChatMessagesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @seller.save(validate: false) if @seller.external_id.blank?
    @community = communities(:named_seller_product_community)
    @message = community_chat_messages(:named_seller_message_in_named_seller_community)
    sign_in_as_seller(@seller, @seller)
    Feature.activate_user(:communities, @seller)
  end

  teardown do
    Feature.deactivate_user(:communities, @seller)
    restore_protect_against_forgery!
  end

  test "POST create redirects to dashboard when communities feature flag is disabled" do
    Feature.deactivate_user(:communities, @seller)
    post :create, params: { community_id: @community.external_id, message_id: @message.external_id }
    assert_redirected_to dashboard_path
    assert_equal "You are not allowed to perform this action.", flash[:alert]
  end

  test "POST create raises RecordNotFound when community is not found" do
    assert_raises(ActiveRecord::RecordNotFound) do
      post :create, params: { community_id: "nonexistent", message_id: @message.external_id }
    end
  end

  test "POST create raises RecordNotFound when message is not found" do
    assert_raises(ActiveRecord::RecordNotFound) do
      post :create, params: { community_id: @community.external_id, message_id: "nonexistent" }
    end
  end

  test "POST create marks a message as read and redirects" do
    post :create, params: { community_id: @community.external_id, message_id: @message.external_id }
    assert_response :see_other
    assert_redirected_to community_path(@community.seller.external_id, @community.external_id)
  end

  test "POST create creates a new LastReadCommunityChatMessage record" do
    LastReadCommunityChatMessage.where(user: @seller, community: @community).destroy_all
    assert_difference -> { LastReadCommunityChatMessage.count }, 1 do
      post :create, params: { community_id: @community.external_id, message_id: @message.external_id }
    end
    last_read = LastReadCommunityChatMessage.last
    assert_equal @seller, last_read.user
    assert_equal @community, last_read.community
    assert_equal @message, last_read.community_chat_message
  end
end
