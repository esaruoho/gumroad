# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. AffiliateRequest spec (386 LOC, 53 create()/build()
# refs) threads through Affiliate / DirectAffiliate / User / Link factories
# plus AffiliateMailer.notify_unregistered_user_invited_to_join /
# AffiliateMailer.direct_affiliate_invitation deliver_later enqueue
# assertions across the approve/ignore/state-machine lifecycle. The
# `User.alive.find_by(email:)` + `create_user!` / `attach_to_user!` paths
# need at least 4 new fixture user rows (existing, unconfirmed, blocked,
# suspended) plus full self_service_affiliate_products wiring on the seller.
# Out of scope for mechanical model backfill.
#
# Original spec: spec/models/affiliate_request_spec.rb
class AffiliateRequestTest < ActiveSupport::TestCase
  test "TODO: migrate — Affiliate/User factory chain + AffiliateMailer enqueue + state-machine fanout" do
    skip "53 create() refs across AffiliateRequest state lifecycle (approve/ignore), Affiliate creation, self_service_affiliate_products lookup, AffiliateMailer deliver_later enqueues. Out of scope for mechanical model backfill."
  end
end
