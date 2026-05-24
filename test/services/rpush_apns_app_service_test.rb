# frozen_string_literal: true

require "test_helper"

class RpushApnsAppServiceTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    Rpush::Apns2::App.all.each(&:destroy)
    @app_name = Device::APP_TYPES[:creator]
  end

  teardown do
    Rpush::Apns2::App.all.each(&:destroy)
  end

  test "first_or_create! returns the existing record when one is present" do
    with_mock_certificate do
      app = RpushApnsAppService.new(name: @app_name).first_or_create!
      assert Rpush::Apns2::App.where(name: @app_name).size.positive?

      before_count = Rpush::Apns2::App.where(name: @app_name).size
      fetched_app = RpushApnsAppService.new(name: @app_name).first_or_create!

      assert_equal app.id, fetched_app.id
      assert_equal before_count, Rpush::Apns2::App.where(name: @app_name).size
    end
  end

  test "first_or_create! creates and returns a new record when none exists" do
    with_mock_certificate do
      before_count = Rpush::Apns2::App.where(name: @app_name).size
      app = RpushApnsAppService.new(name: @app_name).first_or_create!

      assert_equal "development", app.environment
      assert app.certificate.present?
      assert_equal 1, app.connections
      assert_equal before_count + 1, Rpush::Apns2::App.where(name: @app_name).size
    end
  end

  test "first_or_create! creates a production app in staging" do
    with_mock_certificate do
      Rails.env.stub(:staging?, true) do
        before_count = Rpush::Apns2::App.where(name: @app_name).size
        app = RpushApnsAppService.new(name: @app_name).first_or_create!

        assert_equal "production", app.environment
        assert_equal before_count + 1, Rpush::Apns2::App.where(name: @app_name).size
      end
    end
  end

  test "first_or_create! creates a production app in production" do
    with_mock_certificate do
      Rails.env.stub(:production?, true) do
        before_count = Rpush::Apns2::App.where(name: @app_name).size
        app = RpushApnsAppService.new(name: @app_name).first_or_create!

        assert_equal "production", app.environment
        assert_equal before_count + 1, Rpush::Apns2::App.where(name: @app_name).size
      end
    end
  end

  test "#creator_app? returns the correct app type" do
    assert RpushApnsAppService.new(name: Device::APP_TYPES[:creator]).send(:creator_app?)
    assert_not RpushApnsAppService.new(name: Device::APP_TYPES[:consumer]).send(:creator_app?)
  end

  private
    def with_mock_certificate
      original_read = File.method(:read)

      File.stub(:read, ->(path) {
        if path.to_s.include?("certs") && path.to_s.end_with?(".pem")
          mock_certificate
        else
          original_read.call(path)
        end
      }) do
        yield
      end
    end

    def mock_certificate
      key = OpenSSL::PKey::RSA.new(2048)
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = 1
      cert.subject = OpenSSL::X509::Name.parse("/CN=Test Certificate/O=Test/C=US")
      cert.issuer = cert.subject
      cert.public_key = key.public_key
      cert.not_before = Time.current
      cert.not_after = 1.year.from_now
      cert.sign(key, OpenSSL::Digest.new("SHA256"))

      cert.to_pem + key.to_pem
    end
end
