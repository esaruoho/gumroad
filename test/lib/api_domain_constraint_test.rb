# frozen_string_literal: true

require "test_helper"

class ApiDomainConstraintTest < ActiveSupport::TestCase
  Request = Struct.new(:host)

  test "in development environment, returns true for any host" do
    Rails.stub(:env, ActiveSupport::StringInquirer.new("development")) do
      assert_equal true, ApiDomainConstraint.matches?(Request.new("api.gumroad.com"))
      assert_equal true, ApiDomainConstraint.matches?(Request.new("gumroad.com"))
    end
  end

  test "in non-development, returns true for valid API host" do
    with_const(:VALID_API_REQUEST_HOSTS, ["api.gumroad.com"]) do
      assert_equal true, ApiDomainConstraint.matches?(Request.new("api.gumroad.com"))
    end
  end

  test "in non-development, returns false for non-API host" do
    with_const(:VALID_API_REQUEST_HOSTS, ["api.gumroad.com"]) do
      assert_equal false, ApiDomainConstraint.matches?(Request.new("gumroad.com"))
    end
  end
end
