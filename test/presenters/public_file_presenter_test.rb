require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only
# migration: ActiveStorage attach + analyze paths (`public_file.file.analyze`,
# `public_file.file.blob.url`) require a real attached/uploaded blob and
# cannot be replicated mechanically with fixtures.
#
# Original spec: spec/presenters/public_file_presenter_spec.rb
class PublicFilePresenterTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — ActiveStorage attach paths" do
    skip "TODO: migrate spec/presenters/public_file_presenter_spec.rb (ActiveStorage attach + analyze)"
  end
end
