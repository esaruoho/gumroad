# frozen_string_literal: true

require "test_helper"

class ConnectionsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @seller.twitter_user_id = "123"
    @seller.twitter_handle = "gumroad"
    @seller.save!
    sign_in_as_seller(@seller)
  end

  teardown { restore_protect_against_forgery! }

  test "POST unlink_twitter unsets all twitter properties" do
    post :unlink_twitter
    @seller.reload
    User::SocialTwitter::TWITTER_PROPERTIES.each do |property|
      assert_nil @seller.attributes[property]
    end
    assert_equal({ success: true }.to_json, @response.body)
  end

  test "POST unlink_twitter responds with an error message if the unlink fails" do
    orig = User.instance_method(:save!)
    User.define_method(:save!) { |*_a, **_k| raise "Failed to unlink Twitter" }
    begin
      post :unlink_twitter
      assert_equal({ success: false, error_message: "Failed to unlink Twitter" }.to_json, @response.body)
    ensure
      User.define_method(:save!, orig)
    end
  end
end
