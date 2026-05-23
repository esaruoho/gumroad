# frozen_string_literal: true

require "test_helper"

class ProductCustomDomainConstraintTest < ActiveSupport::TestCase
  def request_for(host)
    Struct.new(:host).new(host)
  end

  test "returns false when the host belongs to a user-only custom domain" do
    assert_equal false, ProductCustomDomainConstraint.matches?(request_for("user-only.example.com"))
  end

  test "returns true when the host belongs to a product custom domain" do
    assert_equal true, ProductCustomDomainConstraint.matches?(request_for("with-product.example.com"))
  end

  test "returns false when no custom domain is registered for the host" do
    assert_equal false, ProductCustomDomainConstraint.matches?(request_for("unknown.example.com"))
  end
end
