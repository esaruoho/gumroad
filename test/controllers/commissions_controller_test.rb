# frozen_string_literal: true

require "test_helper"
require "support/controller_seller_auth_helpers"

# Migrated from spec/controllers/commissions_controller_spec.rb.
# Tests for the file-attaching/completion-error paths use ActiveStorage and
# Commission#create_completion_purchase!, which exercise Stripe/VCR in the
# original spec — those branches remain deferred.
class CommissionsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerSellerAuthHelpers

  setup do
    @seller = users(:named_seller)
    @admin = users(:admin_for_named_seller)
    [@seller, @admin].each { |u| u.save(validate: false) if u.external_id.blank? }
    @commission = commissions(:named_seller_commission)
    sign_in_as_seller(@admin, @seller)
  end

  teardown { restore_protect_against_forgery! }

  test "PUT update raises RecordNotFound when commission is not found" do
    assert_raises(ActiveRecord::RecordNotFound) do
      put :update, params: { id: "non_existent_id", file_signed_ids: [] }
    end
  end

  test "POST complete raises RecordNotFound when commission is not found" do
    assert_raises(ActiveRecord::RecordNotFound) do
      post :complete, params: { id: "non_existent_id" }
    end
  end

  test "POST complete returns 422 with error message when completion raises" do
    @commission.define_singleton_method(:create_completion_purchase!) do
      raise ActiveRecord::RecordInvalid.new(self)
    end
    Commission.singleton_class.send(:define_method, :find_by_external_id!) do |_id|
      raise "stubbed"
    end

    begin
      # Use a different approach: stub the instance lookup by stubbing the method
      Commission.singleton_class.send(:remove_method, :find_by_external_id!)
      commission = @commission
      Commission.singleton_class.send(:define_method, :find_by_external_id!) { |_id| commission }
      post :complete, params: { id: @commission.external_id }
      assert_response :unprocessable_entity
      body = JSON.parse(@response.body)
      assert_equal ["Failed to complete commission"], body["errors"]
    ensure
      Commission.singleton_class.send(:remove_method, :find_by_external_id!) if Commission.singleton_class.method_defined?(:find_by_external_id!)
    end
  end
end
