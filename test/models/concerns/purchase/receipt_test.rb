# frozen_string_literal: true

require "test_helper"

class Purchase::ReceiptTest < ActiveSupport::TestCase
  test "TODO: migrate Purchase::Receipt spec" do
    skip "Needs many new fixture tables (charges, customer_email_infos, gifts, url_redirects, product_files w/ pdf) plus stampable-pdf ActiveStorage attachments + Sidekiq job enqueue assertions. Out of scope for skip-batch authorization."
  end
end
