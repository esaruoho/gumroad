# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. This spec was skip-batched during the bulk
# fixtures-only migration. The presenter spec exercises ActiveStorage
# attachments (`create(:thumbnail, ...)` / `product.thumbnail.mark_deleted!`,
# attached image variants and `service_url`) and a multi-table purchase /
# url_redirect / membership-product graph with 18 FactoryBot refs — too
# coupled for a mechanical fixture conversion.
#
# Original spec: spec/presenters/library_presenter_spec.rb (deleted in this commit; see git history)
class LibraryPresenterTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/presenters/library_presenter_spec.rb (ActiveStorage thumbnails + url_redirect chain)"
  end
end
