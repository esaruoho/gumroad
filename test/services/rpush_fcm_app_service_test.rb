# frozen_string_literal: true

require "test_helper"

class RpushFcmAppServiceTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    Rpush::Fcm::App.all.each(&:destroy)
    Modis.with_connection { |redis| redis.flushdb }
    @app_name = Device::APP_TYPES[:consumer]
  end

  teardown do
    Rpush::Fcm::App.all.each(&:destroy)
  end

  test "first_or_create! returns the existing record when one is present" do
    app = RpushFcmAppService.new(name: @app_name).first_or_create!
    assert Rpush::Fcm::App.where(name: @app_name).size > 0

    before_count = Rpush::Fcm::App.where(name: @app_name).size
    fetched_app = RpushFcmAppService.new(name: @app_name).first_or_create!
    assert_equal app.id, fetched_app.id
    assert_equal before_count, Rpush::Fcm::App.where(name: @app_name).size
  end

  test "first_or_create! creates and returns a new record when none exists" do
    before_count = Rpush::Fcm::App.where(name: @app_name).size
    app = RpushFcmAppService.new(name: @app_name).first_or_create!
    assert_equal 1, app.connections
    assert_equal before_count + 1, Rpush::Fcm::App.where(name: @app_name).size
  end

  test "first_or_create! builds Rpush::Fcm::App with correct params" do
    json_key = GlobalConfig.get("RPUSH_CONSUMER_FCM_JSON_KEY")
    firebase_project_id = GlobalConfig.get("RPUSH_CONSUMER_FCM_FIREBASE_PROJECT_ID")

    captured = nil
    original_new = Rpush::Fcm::App.method(:new)
    Rpush::Fcm::App.define_singleton_method(:new) do |*args, **kwargs|
      captured = kwargs
      original_new.call(*args, **kwargs)
    end

    begin
      RpushFcmAppService.new(name: @app_name).first_or_create!
    ensure
      Rpush::Fcm::App.singleton_class.send(:remove_method, :new) rescue nil
      Rpush::Fcm::App.define_singleton_method(:new, original_new)
    end

    assert_equal @app_name, captured[:name]
    assert_equal json_key, captured[:json_key]
    assert_equal firebase_project_id, captured[:firebase_project_id]
    assert_equal 1, captured[:connections]
  end
end
