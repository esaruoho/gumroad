# frozen_string_literal: true

require "test_helper"

class EmailSuppressionManagerTest < ActiveSupport::TestCase
  # Sharpened skip-stub.
  # spec/services/email_suppression_manager_spec.rb is `:vcr`-tagged and uses
  # `receive_message_chain(:bounces, :_, :delete, :status_code)` and
  # `_any_instance_of(SendGrid::Client)` extensively across 4+ subusers x
  # 4 lists. Migrating to fixtures-only Minitest requires building a deep
  # SendGrid client/suppression/list/email fake (each `._(email)` returns
  # another object with `.delete`/`.get` returning a status object). Out of
  # scope for the leaf-backfill budget — VCR cassettes + 4-deep mock chains.
  test "TODO: migrate spec/services/email_suppression_manager_spec.rb (VCR + deep SendGrid client chain)" do
    skip "Awaiting SendGrid client fake harness"
  end
end
