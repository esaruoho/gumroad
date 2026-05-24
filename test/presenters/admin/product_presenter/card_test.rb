# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only
# migration. Requires:
#   - :named_user factory equivalent (a fixture user with display name set).
#     Existing users.yml does have named_seller; suspended/flagged variants
#     would need new rows with appropriate flag bits.
#   - :product_with_discord_integration setup → integrations + product_integrations
#     fixture tables (don't currently exist).
#   - :membership_product_with_preset_tiered_pricing → variant_categories +
#     variants + tier-pricing scaffolding (Tier 3+ fixture surface).
#   - prices.yml entries for every product fixture (per skill pitfall).
#   - product_files.yml row(s) with deleted_at variants.
# Spec also exercises `cover_placeholder_url` (asset pipeline), `html_safe_description`
# (Nokogiri-based sanitizer), and SellerContext/Pundit user — convertible bits
# but multiplied by 4+ new fixture tables ⇒ skip-batch.
#
# Original spec: spec/presenters/admin/product_presenter/card_spec.rb (14 FactoryBot refs)
class Admin::ProductPresenter::CardTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — needs integrations/variants/product_files fixtures" do
    skip "TODO: migrate spec/presenters/admin/product_presenter/card_spec.rb (14 FB refs; needs integrations + variants + tier-pricing fixtures)"
  end
end
