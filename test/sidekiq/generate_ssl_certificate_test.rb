# frozen_string_literal: true

require "test_helper"

class GenerateSslCertificateTest < ActiveSupport::TestCase
  setup do
    @custom_domain = custom_domains(:user_domain_user_only)
  end

  test "invokes SslCertificates::Generate when production and domain not deleted" do
    SslCertificates::Generate.stub(:supported_environment?, true) do
      called = []
      obj = Object.new
      obj.define_singleton_method(:process) { called << :process }
      SslCertificates::Generate.stub(:new, ->(d) { called << [:new, d]; obj }) do
        GenerateSslCertificate.new.perform(@custom_domain.id)
      end
      assert_equal [[:new, @custom_domain], :process], called
    end
  end

  test "does not invoke SslCertificates::Generate when custom domain is deleted" do
    @custom_domain.mark_deleted!
    SslCertificates::Generate.stub(:supported_environment?, true) do
      new_called = false
      SslCertificates::Generate.stub(:new, ->(_d) { new_called = true; flunk "should not call" }) do
        GenerateSslCertificate.new.perform(@custom_domain.id)
      end
      assert_equal false, new_called
    end
  end

  test "does not invoke SslCertificates::Generate when environment unsupported" do
    SslCertificates::Generate.stub(:supported_environment?, false) do
      SslCertificates::Generate.stub(:new, ->(_d) { flunk "should not call" }) do
        GenerateSslCertificate.new.perform(@custom_domain.id)
      end
    end
  end
end
