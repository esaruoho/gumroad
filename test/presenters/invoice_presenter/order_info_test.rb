require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during mig-b presenter sweep.
# Blockers: 25 FB refs, composed-presenter (InvoicePresenter::OrderInfo aggregates
# purchase/charge/order graph), needs :purchase_in_progress, :chargeable,
# :zip_tax_rate factories with no fixture rows yet for that shape.
# Original spec: spec/presenters/invoice_presenter/order_info_spec.rb (deleted; see git history)
class InvoicePresenter::OrderInfoTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — composed presenter + missing zip_tax_rate/chargeable fixture shape" do
    skip "TODO: migrate spec/presenters/invoice_presenter/order_info_spec.rb (25 FB refs; needs purchase/charge/order fixture graph + zip_tax_rates)"
  end
end
