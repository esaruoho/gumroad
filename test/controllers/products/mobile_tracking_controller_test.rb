# frozen_string_literal: true

require "test_helper"

class Products::MobileTrackingControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @product = links(:named_seller_product)
  end

  test "GET show assigns props for tracking" do
    called_with = nil
    original_new = MobileTrackingPresenter.method(:new)
    MobileTrackingPresenter.define_singleton_method(:new) do |**kwargs|
      called_with = kwargs
      original_new.call(**kwargs)
    end

    get :show, params: { link_id: @product.unique_permalink }

    assert_response :ok
    assert_template :show
    assert_equal @product.unique_permalink, assigns[:tracking_props][:permalink]
    assert_equal @product.user, called_with[:seller]
  ensure
    MobileTrackingPresenter.singleton_class.send(:remove_method, :new) rescue nil
    MobileTrackingPresenter.define_singleton_method(:new, original_new) if original_new
  end
end
