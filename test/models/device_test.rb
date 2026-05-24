require "test_helper"

class DeviceTest < ActiveSupport::TestCase
  setup do
    @user = users(:named_seller)
  end

  def build_device(attrs = {})
    Device.new({
      token: "x" * 64,
      app_version: "1.0.0",
      device_type: "ios",
      app_type: Device::APP_TYPES[:creator],
      user: @user,
    }.merge(attrs))
  end

  test "creating deletes existing token if already linked with other account" do
    device = build_device(token: "y" * 64, device_type: "ios")
    device.save!
    other = build_device(token: "y" * 64, device_type: "ios")
    other.save!
    assert_empty Device.where(id: device.id)
  end

  test "token is present" do
    assert build_device(token: "x" * 64).valid?
  end

  test "token is not present" do
    assert build_device(token: nil).invalid?
  end

  test "device_type is present" do
    assert build_device(device_type: Device::DEVICE_TYPES.values.first).valid?
  end

  test "device_type is not present" do
    assert build_device(device_type: nil).invalid?
  end

  test "device_type is invalid type" do
    assert build_device(device_type: "windows").invalid?
  end

  test "app_type is present" do
    assert build_device(app_type: Device::APP_TYPES.values.first).valid?
  end

  test "app_type is not present" do
    assert build_device(app_type: nil).invalid?
  end

  test "app_type is invalid type" do
    assert build_device(app_type: "windows").invalid?
  end
end
