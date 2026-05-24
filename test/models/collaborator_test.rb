# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Collaborator spec (223 LOC, 23 create() refs)
# covers shoulda-matchers `is_expected.to belong_to(:seller)` style
# associations + the apply_for_product / dual-percentage / invitation
# lifecycle. The shoulda-matchers DSL has no Minitest port in this lane.
# Beyond that, every collaborator factory chains User (seller + affiliate_user)
# + ProductsAndCollaborators join rows + CollaboratorInvitation +
# AffiliateMailer enqueue assertions. Out of scope for mechanical model
# backfill.
#
# Original spec: spec/models/collaborator_spec.rb
class CollaboratorTest < ActiveSupport::TestCase
  test "TODO: migrate — shoulda-matchers + dual-user factory chain + CollaboratorInvitation" do
    skip "23 create() refs through Collaborator + User (seller + affiliate_user) + products_and_collaborators + CollaboratorInvitation lifecycle; shoulda-matchers `is_expected.to` DSL not loaded in Minitest lane. Out of scope for mechanical model backfill."
  end
end
