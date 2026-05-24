require "test_helper"

class SalesExportChunkTest < ActiveSupport::TestCase
  fixtures :sales_exports

  test "can be created" do
    chunk = SalesExportChunk.create!(export: sales_exports(:basic_export))
    assert chunk.persisted?
  end
end
