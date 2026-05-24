# frozen_string_literal: true

require "test_helper"

class ApplicationControllerTest < ActionController::TestCase
  # ApplicationController is abstract; assert structural properties.
  test "is a subclass of ActionController::Base" do
    assert_operator ApplicationController, :<, ActionController::Base
  end

  test "includes CurrentSeller concern" do
    assert_includes ApplicationController.ancestors, CurrentSeller
  end

  test "responds to set_gumroad_guid before_action helper" do
    assert ApplicationController.private_method_defined?(:set_gumroad_guid)
  end
end
