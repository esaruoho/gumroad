# frozen_string_literal: true

require "test_helper"

class Collaborator::UpdateServiceTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @seller = users(:csu_seller)
    @collaborator = affiliates(:csu_collaborator)
    @product1 = links(:csu_product_1)
    @product2 = links(:csu_product_2)
    @product3 = links(:csu_product_3)
  end

  test "with apply_to_all_products true updates collaborator and product affiliates" do
    params = {
      apply_to_all_products: true,
      percent_commission: 50,
      products: [{ id: @product2.external_id }, { id: @product3.external_id }],
    }

    result = nil
    assert_enqueued_email_with(AffiliateMailer, :collaborator_update, args: [@collaborator.id]) do
      result = Collaborator::UpdateService.new(seller: @seller, collaborator_id: @collaborator.external_id, params:).process
    end

    assert_equal({ success: true }, result)

    @collaborator.reload
    assert_equal 50_00, @collaborator.affiliate_basis_points
    assert @collaborator.apply_to_all_products
    assert_equal [@product2, @product3].sort_by(&:id), @collaborator.products.sort_by(&:id)
    assert_equal 50_00, @collaborator.product_affiliates.find_by(product: @product2).affiliate_basis_points
    assert_equal 50_00, @collaborator.product_affiliates.find_by(product: @product3).affiliate_basis_points
  end

  test "with apply_to_all_products false uses per-product percent_commission" do
    @collaborator.update!(apply_to_all_products: true)

    params = {
      apply_to_all_products: false,
      percent_commission: nil,
      products: [
        { id: @product2.external_id, percent_commission: 25 },
        { id: @product3.external_id, percent_commission: 50 },
      ],
    }

    result = Collaborator::UpdateService.new(seller: @seller, collaborator_id: @collaborator.external_id, params:).process

    assert_equal({ success: true }, result)
    @collaborator.reload
    # does not set default commission to nil
    assert_equal 40_00, @collaborator.affiliate_basis_points
    refute @collaborator.apply_to_all_products
    assert_equal [@product2, @product3].sort_by(&:id), @collaborator.products.sort_by(&:id)
    assert_equal 25_00, @collaborator.product_affiliates.find_by(product: @product2).affiliate_basis_points
    assert_equal 50_00, @collaborator.product_affiliates.find_by(product: @product3).affiliate_basis_points
  end

  test "raises if the collaborator does not belong to the seller" do
    outsider = affiliates(:csu_outsider_collaborator)
    params = {
      apply_to_all_products: true,
      percent_commission: 50,
      products: [{ id: @product2.external_id }],
    }

    assert_raises(ActiveRecord::RecordNotFound) do
      Collaborator::UpdateService.new(seller: @seller, collaborator_id: outsider.external_id, params:).process
    end
  end

  test "raises if a product cannot be found" do
    params = {
      apply_to_all_products: true,
      percent_commission: 50,
      products: [{ id: SecureRandom.hex }],
    }

    assert_raises(ActiveRecord::RecordNotFound) do
      Collaborator::UpdateService.new(seller: @seller, collaborator_id: @collaborator.external_id, params:).process
    end
  end
end
