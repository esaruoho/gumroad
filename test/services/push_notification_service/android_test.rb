# frozen_string_literal: true

require "test_helper"

class PushNotificationService::AndroidTest < ActiveSupport::TestCase
  setup do
    Feature.activate(:send_notifications_to_android_devices)
    @recorder = []
    recorder = @recorder

    @fake_notification = Object.new
    captured = @recorder
    %i[app= alert= device_token= content_available= sound= notification= data= save!].each do |m|
      @fake_notification.define_singleton_method(m) do |*args|
        captured << [m, args.first]
        nil
      end
    end

    fake_notif = @fake_notification
    @orig_new = Rpush::Fcm::Notification.method(:new)
    Rpush::Fcm::Notification.define_singleton_method(:new) { fake_notif }

    @fake_app = Object.new
    fake_app = @fake_app
    @orig_consumer_app = PushNotificationService::Android.method(:consumer_app)
    PushNotificationService::Android.define_singleton_method(:consumer_app) { fake_app }
  end

  teardown do
    Rpush::Fcm::Notification.define_singleton_method(:new, @orig_new) if @orig_new
    PushNotificationService::Android.define_singleton_method(:consumer_app, @orig_consumer_app) if @orig_consumer_app
  end

  test "consumer app: creates FCM notification with sound" do
    sound = Device::NOTIFICATION_SOUNDS[:sale]
    PushNotificationService::Android.new(
      device_token: "ABC", title: "Test", body: "Test body",
      app_type: Device::APP_TYPES[:consumer], sound: sound
    ).process

    calls = @recorder.to_h
    assert_equal @fake_app, calls[:app=]
    assert_equal "Test", calls[:alert=]
    assert_equal "ABC", calls[:device_token=]
    assert_equal true, calls[:content_available=]
    assert_equal sound, calls[:sound=]
    assert_equal({ title: "Test", body: "Test body", icon: "notification_icon", channel_id: "Purchases" }, calls[:notification=])
    assert_equal({ message: "Test" }, calls[:data=])
    assert_includes @recorder.map(&:first), :save!
  end

  test "consumer app: creates FCM notification without sound" do
    PushNotificationService::Android.new(
      device_token: "ABC", title: "Test", body: "Test body",
      app_type: Device::APP_TYPES[:consumer]
    ).process

    calls = @recorder.to_h
    refute_includes @recorder.map(&:first), :sound=
    assert_equal({ title: "Test", body: "Test body", icon: "notification_icon" }, calls[:notification=])
    assert_equal({ message: "Test" }, calls[:data=])
  end

  test "skips when feature is off" do
    Feature.deactivate(:send_notifications_to_android_devices)
    PushNotificationService::Android.new(
      device_token: "ABC", title: "T", body: "B", app_type: Device::APP_TYPES[:consumer]
    ).process
    assert_empty @recorder
  end

  test "skips for creator app type" do
    PushNotificationService::Android.new(
      device_token: "ABC", title: "T", body: "B", app_type: Device::APP_TYPES[:creator]
    ).process
    assert_empty @recorder
  end
end
