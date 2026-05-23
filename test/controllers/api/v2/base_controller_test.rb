# frozen_string_literal: true

require "test_helper"

class Api::V2::BaseControllerTest < ActionController::TestCase
  test "is defined" do
    assert_kind_of Class, Api::V2::BaseController
  end
end
