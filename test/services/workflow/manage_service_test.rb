# frozen_string_literal: true

require "test_helper"

# Skip-batched per gumroad-fixtures-migration directive.
# Original spec: spec/services/workflow/manage_service_spec.rb (17 FB refs).
#
# Reasons:
# - Deep web: workflow, installment, workflow_installment, payment_completed,
#   merchant_account_stripe_connect, purchase — 6+ net-new fixture tables across
#   abandoned-cart, publish/unpublish, affiliate, filter branches.
# - publish! path requires confirmed seller + completed payment + connected stripe
#   account; each branch needs orthogonal setup that doesn't share with neighbors.
# - Inline AR-only construction would either trip validations
#   (Workflow#schedule_installment side effects) or require near-spec-equivalent
#   factory replacement helpers, defeating the fixtures-only directive.
class Workflow::ManageServiceTest < ActiveSupport::TestCase
  test "TODO: migrate spec/services/workflow/manage_service_spec.rb (skip-batched, deep multi-table web)" do
    skip "Skip-batched: workflow + installment + payment + stripe-connect deep web"
  end
end
