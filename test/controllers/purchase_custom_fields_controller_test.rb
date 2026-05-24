# frozen_string_literal: true

require "test_helper"

class PurchaseCustomFieldsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "POST create raises ActiveRecord::RecordNotFound when purchase is missing" do
    assert_raises(ActiveRecord::RecordNotFound) do
      post :create, params: { purchase_id: "doesnotexist", custom_field_id: "x", value: "v" }
    end
  end

  test "POST create requires purchase_id parameter" do
    assert_raises(ActionController::ParameterMissing) do
      post :create, params: { custom_field_id: "x", value: "v" }
    end
  end
end
