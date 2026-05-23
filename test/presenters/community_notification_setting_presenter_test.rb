# frozen_string_literal: true

require "test_helper"

class CommunityNotificationSettingPresenterTest < ActiveSupport::TestCase
  test "returns appropriate props" do
    settings = community_notification_settings(:basic_user_for_named_seller_daily)
    presenter = CommunityNotificationSettingPresenter.new(settings:)
    assert_equal({ recap_frequency: "daily" }, presenter.props)
  end

  test "returns weekly recap frequency" do
    settings = community_notification_settings(:purchaser_for_named_seller_weekly)
    presenter = CommunityNotificationSettingPresenter.new(settings:)
    assert_equal "weekly", presenter.props[:recap_frequency]
  end

  test "returns nil recap frequency when not set" do
    settings = community_notification_settings(:collaborating_for_named_seller_nil)
    presenter = CommunityNotificationSettingPresenter.new(settings:)
    assert_nil presenter.props[:recap_frequency]
  end
end
