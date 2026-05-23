# frozen_string_literal: true

require "test_helper"

class ChargeableVisualTest < ActiveSupport::TestCase
  test "is_cc_visual returns true for a credit card visual" do
    assert_equal true, ChargeableVisual.is_cc_visual("**** **** **** 4242")
  end

  test "is_cc_visual returns false for a weird credit card visual" do
    assert_equal false, ChargeableVisual.is_cc_visual("***A **** **** 4242")
  end

  test "is_cc_visual returns false for an email address" do
    assert_equal false, ChargeableVisual.is_cc_visual("hi@gumroad.com")
  end

  test "build_visual formats all types properly based on card number length" do
    assert_equal "**** **** **** 4242", ChargeableVisual.build_visual("4242", 16)
    assert_equal "**** **** **** *242", ChargeableVisual.build_visual("242", 16)
    assert_equal "**** **** **** 4242", ChargeableVisual.build_visual("4000 0000 0000 4242", 16)
    assert_equal "**** ****** *4242", ChargeableVisual.build_visual("4242", 15)
    assert_equal "**** ****** 4242", ChargeableVisual.build_visual("4242", 14)
    assert_equal "**** **** **** 4242", ChargeableVisual.build_visual("4242", 20)
  end

  test "build_visual filters out everything but numbers" do
    assert_equal "**** **** **** 4242", ChargeableVisual.build_visual("-42-42", 16)
    assert_equal "**** **** **** 4242", ChargeableVisual.build_visual(" 4+2@4 2", 16)
    assert_equal "**** **** **** 4242", ChargeableVisual.build_visual("4%2$4!2", 16)
    assert_equal "**** **** **** 4242", ChargeableVisual.build_visual("4_2*4&2", 16)
    assert_equal "**** **** **** 4242", ChargeableVisual.build_visual("4%2B4a2", 16)
  end
end
