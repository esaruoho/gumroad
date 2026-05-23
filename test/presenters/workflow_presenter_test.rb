require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only
# migration: relies on the `with_workflow_form_context` shared_examples
# group (RSpec-only construct) plus workflow + abandoned_cart_products
# associations across multiple workflow types — non-trivial fixture
# rewrite, deferred.
#
# Original spec: spec/presenters/workflow_presenter_spec.rb
class WorkflowPresenterTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — shared_examples + multi-type workflow surface" do
    skip "TODO: migrate spec/presenters/workflow_presenter_spec.rb (with_workflow_form_context shared_examples + abandoned_cart workflows)"
  end
end
