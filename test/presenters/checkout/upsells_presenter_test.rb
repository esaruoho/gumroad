require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during mig-b presenter sweep.
# Blockers: depends on :upsell, :upsell_variant, :upsell_purchase, :product_with_digital_versions
# factories (digital-version variants + 20 upsell_purchase rows + cross-sell graph).
# No fixture shape yet for upsell_purchases.yml or product variants list expected here.
# Original spec: spec/presenters/checkout/upsells_presenter_spec.rb (deleted; see git history)
class Checkout::UpsellsPresenterTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — needs upsell_variant/upsell_purchase + digital-version variant fixture shape" do
    skip "TODO: migrate spec/presenters/checkout/upsells_presenter_spec.rb (9 FB refs; upsell_purchase + variant fixture shape missing)"
  end
end
