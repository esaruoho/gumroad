# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Comment spec (237 LOC, 33 create() refs) covers
# `commentable: create(:published_installment)` content-length validations
# (Installment factory chain) plus `purchase: create(:purchase)`
# author resolution + admin / payout_note comment-type subclasses (STI on
# `comment_type` column). Installment factory requires Link + Seller +
# InstallmentRule; Purchase chain requires cc_token_chargeable (heavy
# validations). Out of scope for mechanical model backfill.
#
# Original spec: spec/models/comment_spec.rb
class CommentTest < ActiveSupport::TestCase
  test "TODO: migrate — Installment + Purchase factory chain + comment_type STI" do
    skip "33 create() refs through Installment (Link + Seller + InstallmentRule) + Purchase (cc_token_chargeable) + comment_type STI subclasses. Out of scope for mechanical model backfill."
  end
end
