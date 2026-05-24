# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during fixtures-only migration.
# Requires `collaborators.yml` (with deleted/confirmed/pending states),
# `collaborator_invitations.yml` rows wired to the pending collaborator, and
# the CollaboratorPresenter#collaborator_props chain (which needs affiliate
# user fixtures, product associations, percentages, etc.). Tier 3 —
# CollaboratorPresenter has its own dependency tree that should be migrated
# first.
#
# Original spec: spec/presenters/collaborators_presenter_spec.rb (deleted)
class CollaboratorsPresenterTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — collaborators/collaborator_invitations fixtures + CollaboratorPresenter chain" do
    skip "TODO: migrate spec/presenters/collaborators_presenter_spec.rb (6 FB refs, needs collaborators + CollaboratorPresenter chain)"
  end
end
