# frozen_string_literal: true

require "test_helper"

class PushNotificationServiceIosTest < ActiveSupport::TestCase
  test "creates a creator app APNS notification" do
    app = Object.new
    notification = Minitest::Mock.new
    notification.expect(:save!, true)
    device_token = "ABC"
    title = "Test"
    body = "Body"
    expected_payload = {
      app:,
      device_token:,
      alert: { "title" => title, "body" => body },
      sound: "chaching.wav",
      data: { headers: { "apns-topic": "com.GRD.iOSCreator" } }
    }

    process_notification(
      app_method: :creator_app,
      app:,
      notification:,
      expected_payload:,
      device_token:,
      title:,
      body:,
      app_type: Device::APP_TYPES[:creator],
      sound: Device::NOTIFICATION_SOUNDS[:sale]
    )

    notification.verify
  end

  test "creates a consumer app APNS notification with sound" do
    app = Object.new
    notification = Minitest::Mock.new
    notification.expect(:save!, true)
    device_token = "ABC"
    title = "Test"
    body = "Body"
    expected_payload = {
      app:,
      device_token:,
      alert: { "title" => title, "body" => body },
      sound: "chaching.wav",
      data: { headers: { "apns-topic": "com.GRD.Gumroad" } }
    }

    process_notification(
      app_method: :consumer_app,
      app:,
      notification:,
      expected_payload:,
      device_token:,
      title:,
      body:,
      app_type: Device::APP_TYPES[:consumer],
      sound: Device::NOTIFICATION_SOUNDS[:sale]
    )

    notification.verify
  end

  test "creates a consumer app APNS notification without sound" do
    app = Object.new
    notification = Minitest::Mock.new
    notification.expect(:save!, true)
    device_token = "ABC"
    title = "Test"
    body = "Body"
    expected_payload = {
      app:,
      device_token:,
      alert: { "title" => title, "body" => body },
      data: { headers: { "apns-topic": "com.GRD.Gumroad" } }
    }

    process_notification(
      app_method: :consumer_app,
      app:,
      notification:,
      expected_payload:,
      device_token:,
      title:,
      body:,
      app_type: Device::APP_TYPES[:consumer]
    )

    notification.verify
  end

  test "sets a plain alert when the consumer notification body is empty" do
    app = Object.new
    notification = Minitest::Mock.new
    notification.expect(:save!, true)
    device_token = "ABC"
    title = "Test"
    expected_payload = {
      app:,
      device_token:,
      alert: title,
      data: { headers: { "apns-topic": "com.GRD.Gumroad" } }
    }

    process_notification(
      app_method: :consumer_app,
      app:,
      notification:,
      expected_payload:,
      device_token:,
      title:,
      body: nil,
      app_type: Device::APP_TYPES[:consumer]
    )

    notification.verify
  end

  private
    def process_notification(app_method:, app:, notification:, expected_payload:, device_token:, title:, body:, app_type:, sound: nil)
      notification_builder = lambda do |payload|
        assert_equal expected_payload, payload
        notification
      end

      PushNotificationService::Ios.stub(app_method, app) do
        Rpush::Apns2::Notification.stub(:new, notification_builder) do
          PushNotificationService::Ios.new(device_token:, title:, body:, app_type:, sound:).process
        end
      end
    end
end
