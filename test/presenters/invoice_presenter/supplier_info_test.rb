require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during mig-b presenter sweep.
# Blockers: composed-presenter (InvoicePresenter::SupplierInfo), needs charge+order+
# physical_product fixture graph not present; 14 FB refs.
# Original spec: spec/presenters/invoice_presenter/supplier_info_spec.rb (deleted; see git history)
class InvoicePresenter::SupplierInfoTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — composed presenter + missing charge/order/physical_product fixture shape" do
    skip "TODO: migrate spec/presenters/invoice_presenter/supplier_info_spec.rb (14 FB refs; charge/order/physical_product fixture graph missing)"
  end
end
