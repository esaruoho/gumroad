# frozen_string_literal: true

require "test_helper"

class Integrations::CircleIntegrationServiceTest < ActiveSupport::TestCase
  setup do
    @email = "test_circle_integration@gumroad.com"
    @product = links(:named_seller_product)
    @product_without_integration = links(:basic_user_product)
    @integration = integrations(:circle_integration_one)
    @variant = base_variants(:integrations_test_variant_v1)
    @variant_integration = integrations(:circle_integration_for_variant_one)
    @variant_without_integration = Variant.create!(
      variant_category: @variant.variant_category,
      name: "No Circle integration"
    )

    ProductIntegration.where(product_id: [@product.id, @product_without_integration.id]).delete_all
    BaseVariantIntegration.where(base_variant_id: [@variant.id, @variant_without_integration.id]).delete_all
    ProductIntegration.create!(product: @product, integration: @integration)
    BaseVariantIntegration.create!(base_variant: @variant, integration: @variant_integration)
    @integration.update_columns(flags: 0)
    @variant_integration.update_columns(flags: 0)
  end

  test "activate adds member for product integration" do
    assert_circle_api_called(:add_member, @integration.community_id, @integration.space_group_id, @email) do
      service.activate(purchase_for(@product))
    end
  end

  test "activate does nothing when product has no Circle integration" do
    assert_circle_api_not_called do
      service.activate(purchase_for(@product_without_integration))
    end
  end

  test "deactivate removes member for product integration" do
    assert_circle_api_called(:remove_member, @integration.community_id, @email) do
      service.deactivate(purchase_for(@product))
    end
  end

  test "deactivate does nothing when product has no Circle integration" do
    assert_circle_api_not_called do
      service.deactivate(purchase_for(@product_without_integration))
    end
  end

  test "deactivate does nothing when integration keeps inactive members" do
    @integration.update!(keep_inactive_members: true)

    assert_circle_api_not_called do
      service.deactivate(purchase_for(@product))
    end
  end

  test "activate adds member for selected variant integration" do
    assert_circle_api_called(:add_member, @variant_integration.community_id, @variant_integration.space_group_id, @email) do
      service.activate(purchase_for(@product, variant: @variant))
    end
  end

  test "activate does nothing when selected variant has no Circle integration" do
    assert_circle_api_not_called do
      service.activate(purchase_for(@product, variant: @variant_without_integration))
    end
  end

  test "deactivate removes member for selected variant integration" do
    assert_circle_api_called(:remove_member, @variant_integration.community_id, @email) do
      service.deactivate(purchase_for(@product, variant: @variant))
    end
  end

  test "deactivate does nothing for selected variant when deactivation is disabled" do
    @variant_integration.update!(keep_inactive_members: true)

    assert_circle_api_not_called do
      service.deactivate(purchase_for(@product, variant: @variant))
    end
  end

  test "purchase without variant uses product integration" do
    assert_circle_api_called(:add_member, @integration.community_id, @integration.space_group_id, @email) do
      service.activate(purchase_for(@product))
    end
  end

  private
    def assert_circle_api_called(method_name, *expected_args)
      calls = []
      fake_api = circle_api_fake(calls)

      CircleApi.stub(:new, fake_api) do
        yield
      end

      assert_equal [[method_name, expected_args]], calls
    end

    def assert_circle_api_not_called
      calls = []
      fake_api = circle_api_fake(calls)

      CircleApi.stub(:new, fake_api) do
        yield
      end

      assert_empty calls
    end

    def circle_api_fake(calls)
      Object.new.tap do |fake_api|
        fake_api.define_singleton_method(:add_member) { |*args| calls << [:add_member, args] }
        fake_api.define_singleton_method(:remove_member) { |*args| calls << [:remove_member, args] }
      end
    end

    def service
      Integrations::CircleIntegrationService.new
    end

    def purchase_for(product, variant: nil)
      purchase = Purchase.new(
        link: product,
        seller: product.user,
        email: @email,
        price_cents: product.price_cents,
        displayed_price_cents: product.price_cents,
        total_transaction_cents: product.price_cents,
        purchase_state: "successful"
      )
      purchase.save!(validate: false)
      purchase.variant_attributes << variant if variant.present?
      purchase
    end
end
