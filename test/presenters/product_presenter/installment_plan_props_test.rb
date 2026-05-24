# frozen_string_literal: true

require "test_helper"

class ProductPresenter::InstallmentPlanPropsTest < ActiveSupport::TestCase
  test "props returns correct props when product has no installment plan" do
    product = links(:basic_user_product) # eligible (digital, not membership) and no plan fixture
    presenter = ProductPresenter::InstallmentPlanProps.new(product:)

    assert_equal(
      {
        eligible_for_installment_plans: true,
        allow_installment_plan: false,
        installment_plan: nil
      },
      presenter.props
    )
  end

  test "props returns correct props with installment plan details" do
    product = links(:po_test_installment_product) # fixture installment plan: 4 monthly
    presenter = ProductPresenter::InstallmentPlanProps.new(product:)

    assert_equal(
      {
        eligible_for_installment_plans: true,
        allow_installment_plan: true,
        installment_plan: {
          number_of_installments: 4,
          recurrence: "monthly"
        }
      },
      presenter.props
    )
  end

  test "props returns correct props when product is not eligible (membership)" do
    product = links(:footer_membership_product)
    presenter = ProductPresenter::InstallmentPlanProps.new(product:)

    assert_equal(
      {
        eligible_for_installment_plans: false,
        allow_installment_plan: false,
        installment_plan: nil
      },
      presenter.props
    )
  end
end
