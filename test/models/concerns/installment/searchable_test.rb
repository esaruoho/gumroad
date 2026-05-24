# frozen_string_literal: true

require "test_helper"

class Installment::SearchableTest < ActiveSupport::TestCase
  setup do
    @installment = installments(:searchable_first_post)
  end

  test "#as_indexed_json includes all fields" do
    expected = {
      "message" => "<p>body</p>",
      "created_at" => @installment.created_at.utc.iso8601,
      "deleted_at" => nil,
      "published_at" => @installment.published_at.utc.iso8601,
      "id" => @installment.id,
      "seller_id" => @installment.seller_id,
      "workflow_id" => @installment.workflow_id,
      "name" => "First post",
      "selected_flags" => ["send_emails", "allow_comments"],
    }
    assert_equal expected, @installment.as_indexed_json
  end

  test "#as_indexed_json allows only a selection of fields to be used" do
    assert_equal({ "name" => "First post" }, @installment.as_indexed_json(only: ["name"]))
  end
end
