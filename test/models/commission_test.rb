# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Commission spec (341 LOC, 30 create() refs) is
# `:vcr`-tagged top-level and threads create_completion_purchase through the
# Stripe charge flow (PaymentIntent capture, $/cents calculation under VCR
# cassettes) plus `commission_completed` mailer enqueue. The
# `:commission_product` factory wires Link + Commission + deposit/completion
# pricing under Stripe. Out of scope for mechanical model backfill.
#
# Original spec: spec/models/commission_spec.rb
class CommissionTest < ActiveSupport::TestCase
  test "TODO: migrate — :vcr + create_completion_purchase + Stripe PaymentIntent" do
    skip "Top-level :vcr; 30 create() refs through commission_product + create_completion_purchase + Stripe PaymentIntent capture + ContactingCreatorMailer enqueue. Out of scope for mechanical model backfill."
  end
end
