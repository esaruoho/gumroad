# frozen_string_literal: true

require "test_helper"

class CommunityNotificationSettingTest < ActiveSupport::TestCase
  setup do
    @user = users(:named_seller)
    @seller = users(:basic_user)
  end

  test "belongs_to :user" do
    assoc = CommunityNotificationSetting.reflect_on_association(:user)
    assert_equal :belongs_to, assoc.macro
  end

  test "belongs_to :seller class_name User" do
    assoc = CommunityNotificationSetting.reflect_on_association(:seller)
    assert_equal :belongs_to, assoc.macro
    assert_equal "User", assoc.class_name
  end

  test "validates uniqueness of user_id scoped to seller_id" do
    CommunityNotificationSetting.create!(user: @user, seller: @seller, recap_frequency: "daily")
    dup = CommunityNotificationSetting.new(user: @user, seller: @seller, recap_frequency: "weekly")
    assert_not dup.valid?
    assert dup.errors[:user_id].present?
  end

  test "defines string enum recap_frequency with daily/weekly and prefix" do
    assert_equal({ "daily" => "daily", "weekly" => "weekly" }, CommunityNotificationSetting.recap_frequencies)
    setting = CommunityNotificationSetting.new(user: @user, seller: @seller, recap_frequency: "daily")
    assert setting.recap_frequency_daily?
    setting.recap_frequency = "weekly"
    assert setting.recap_frequency_weekly?
  end
end
