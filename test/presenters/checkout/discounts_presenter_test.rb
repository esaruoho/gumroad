require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during mig-b presenter sweep.
# Blockers: 17 FB refs across :offer_code, :percentage_offer_code,
# :membership_product_with_preset_tiered_pricing, :purchase, :team_membership —
# checkout discounts presenter aggregates offer-code usage stats over purchases
# with no fixture coverage for that join shape yet.
# Original spec: spec/presenters/checkout/discounts_presenter_spec.rb (deleted; see git history)
class Checkout::DiscountsPresenterTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — needs offer_codes + tiered_pricing + purchase aggregation fixtures" do
    skip "TODO: migrate spec/presenters/checkout/discounts_presenter_spec.rb (17 FB refs; offer_code/purchase aggregation shape missing)"
  end
end
