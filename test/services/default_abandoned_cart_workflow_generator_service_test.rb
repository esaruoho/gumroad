# frozen_string_literal: true

require "test_helper"

class DefaultAbandonedCartWorkflowGeneratorServiceTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options
    { host: DOMAIN, protocol: PROTOCOL }
  end

  setup do
    @seller = users(:another_seller)
    @service = DefaultAbandonedCartWorkflowGeneratorService.new(seller: @seller)
  end

  test "#generate creates a new abandoned cart workflow and publishes it" do
    assert_difference -> { @seller.workflows.abandoned_cart_type.published.count }, 1 do
      @service.generate
    end

    workflow = @seller.workflows.abandoned_cart_type.published.sole
    assert_equal "Abandoned cart", workflow.name
    assert_nil workflow.bought_products
    assert_nil workflow.bought_variants

    installment = workflow.installments.alive.sole
    assert_equal "You left something in your cart", installment.name
    assert_equal expected_installment_message, installment.message
    assert installment.abandoned_cart_type?
    assert_equal 24, installment.installment_rule.displayable_time_duration
    assert_equal "hour", installment.installment_rule.time_period
  end

  test "#generate does not create a new abandoned cart workflow when one already exists" do
    @seller.workflows.create!(
      name: "Deleted abandoned cart",
      workflow_type: Workflow::ABANDONED_CART_TYPE,
      deleted_at: 1.hour.ago
    )

    assert_no_difference -> { @seller.workflows.abandoned_cart_type.count } do
      assert_no_difference -> { Installment.count } do
        assert_no_difference -> { InstallmentRule.count } do
          @service.generate
        end
      end
    end
  end

  private
    def expected_installment_message
      [
        "<p>When you're ready to buy, ",
        %(<a href="#{checkout_url(host: DOMAIN)}" target="_blank" rel="noopener noreferrer nofollow">complete checking out</a>.),
        "</p><product-list-placeholder />",
      ].join
    end
end
