require "test_helper"

class SalesExportTest < ActiveSupport::TestCase
  fixtures :sales_exports

  test "#destroy deletes chunks" do
    export = sales_exports(:basic_export)
    SalesExportChunk.create!(export: export)
    assert_equal 1, SalesExportChunk.count
    export.destroy!
    assert_equal 0, SalesExportChunk.count
  end
end
