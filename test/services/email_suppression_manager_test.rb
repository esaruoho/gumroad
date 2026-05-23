# frozen_string_literal: true

require "test_helper"

class EmailSuppressionManagerTest < ActiveSupport::TestCase
  test "TODO: migrate spec/services/email_suppression_manager_spec.rb (deep receive_message_chain on SendGrid::Client, VCR cassette)" do
    skip "Awaiting fixtures migration: requires stub strategy for SendGrid::Client multi-chain (.bounces._.delete.status_code etc) without rspec-mocks receive_message_chain"
  end
end
