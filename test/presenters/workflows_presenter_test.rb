# frozen_string_literal: true

require "test_helper"

class WorkflowsPresenterTest < ActiveSupport::TestCase
  test "#workflows_props returns alive workflows ordered by created_at desc" do
    seller = users(:named_seller)
    w1 = workflows(:workflows_presenter_follower)        # 1 day ago
    w3 = workflows(:workflows_presenter_product)         # 1 hour ago
    w4 = workflows(:workflows_presenter_seller)          # 2 hours ago

    result = WorkflowsPresenter.new(seller:).workflows_props

    assert_equal(
      {
        workflows: [
          WorkflowPresenter.new(seller:, workflow: w3).workflow_props,
          WorkflowPresenter.new(seller:, workflow: w4).workflow_props,
          WorkflowPresenter.new(seller:, workflow: w1).workflow_props
        ]
      },
      result
    )
  end
end
