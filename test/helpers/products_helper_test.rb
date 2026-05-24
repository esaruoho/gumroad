require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration:
# ActiveStorage-attachment heavy (preview uploads via fixture_file_upload,
# preview.retina_variant), plus Elasticsearch indexing (index_model_records(Link))
# and custom_domain / taxonomy / subscription_product factories. Migration
# deferred until AS-attachment fixtures + ES bootstrap are sorted.
#
# Original spec: spec/helpers/products_helper_spec.rb (deleted in this commit)
class ProductsHelperTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — AS-attachment + ES heavy, requires manual rewrite" do
    skip "TODO: migrate spec/helpers/products_helper_spec.rb — ActiveStorage previews + ES indexing"
  end
end
