# frozen_string_literal: true

require "test_helper"

class Api::Mobile::BaseControllerTest < ActionController::TestCase
  test "MOBILE_TOKEN constant is defined" do
    assert_not_nil Api::Mobile::BaseController::MOBILE_TOKEN
  end

  test "inherits from ApplicationController" do
    assert_equal ApplicationController, Api::Mobile::BaseController.superclass
  end

  test "includes Pagy::Backend" do
    assert_includes Api::Mobile::BaseController.ancestors, Pagy::Backend
  end
end
