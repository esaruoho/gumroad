require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only
# migration: `:bundle` trait + `bundle_product` join rows, plus
# `product_with_digital_versions`, SKUs, variant_categories,
# refund_policies, taxonomies, profile_sections — too many net-new
# fixture tables to land mechanically.
#
# Original spec: spec/presenters/bundle_presenter_spec.rb
class BundlePresenterTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — bundle/variant/sku fixture surface" do
    skip "TODO: migrate spec/presenters/bundle_presenter_spec.rb (bundle traits + variants + SKUs + taxonomies)"
  end
end
