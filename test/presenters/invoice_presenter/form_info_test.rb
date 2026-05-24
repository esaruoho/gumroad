require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during mig-b presenter sweep.
# Blockers: composed-presenter chain (InvoicePresenter aggregates form/order/supplier
# sections that share a Charge+Order graph), factories for :charge, :order,
# :physical_product, :product, :named_seller — no fixture rows yet for the
# multi-physical-product order shape this spec asserts on.
# Original spec: spec/presenters/invoice_presenter/form_info_spec.rb (deleted; see git history)
class InvoicePresenter::FormInfoTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — composed-presenter + missing order/charge fixture shape" do
    skip "TODO: migrate spec/presenters/invoice_presenter/form_info_spec.rb (12 FB refs; composed presenter, no order/charge fixture shape)"
  end
end
