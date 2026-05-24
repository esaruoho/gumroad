# frozen_string_literal: true

require "test_helper"

class RenewCustomDomainSslCertificatesTest < ActiveSupport::TestCase
  test "invokes SslCertificates::Renew when in production" do
    renew_double = Minitest::Mock.new
    renew_double.expect(:process, nil)

    Rails.env.stub(:production?, true) do
      SslCertificates::Renew.stub(:new, renew_double) do
        RenewCustomDomainSslCertificates.new.perform
      end
    end

    assert renew_double.verify
  end

  test "does not invoke SslCertificates::Renew outside production" do
    called = false
    SslCertificates::Renew.stub(:new, ->(*) { called = true; nil }) do
      RenewCustomDomainSslCertificates.new.perform
    end

    refute called
  end
end
