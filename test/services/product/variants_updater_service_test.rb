# frozen_string_literal: true

require "test_helper"

class Product::VariantsUpdaterServiceTest < ActiveSupport::TestCase
  # Sharpened skip-stub.
  # Original: spec/services/product/variants_updater_service_spec.rb (255 lines, 20 FB refs)
  # Blocker: VariantCategory + Variant CRUD via nested params (rename/create/delete);
  # additional branches for SKU regeneration, price_difference handling, file embeds,
  # is_pwyw, and is_multiseat_license. external_id-based addressing requires persisted
  # fixtures across category/variant; cross-effect on Link#has_skus? guarded by
  # skus_enabled flag. Defer to dedicated variant fixture chain.
  test "TODO: migrate spec/services/product/variants_updater_service_spec.rb" do
    skip "Fixture-hostile — VariantCategory/Variant nested-params CRUD + SKU regeneration"
  end
end
