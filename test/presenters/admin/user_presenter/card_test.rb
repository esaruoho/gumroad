# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only
# migration. Requires:
#   - :named_user fixture variant (a User with `name` populated for the
#     `props[:name]` assertion; named_seller exists but is reused widely).
#   - comments.yml rows of type Comment::COMMENT_TYPE_NOTE on commentable
#     = the user (extends comments.yml shape with polymorphic commentable_id).
#   - team_memberships.yml row in `admin` role for a fresh seller pair.
#   - user_compliance_infos.yml (new fixture file; columns include is_business,
#     first/last/business names + addresses + state/country codes + tax id flags).
#   - blocked_form_emails / blocked_form_email_domains stubbing (the spec uses
#     RSpec doubles — translatable to Minitest::Mock or stub helpers).
# Five-ish new fixture tables and several stub conversions ⇒ skip-batch.
#
# Original spec: spec/presenters/admin/user_presenter/card_spec.rb (5 FactoryBot refs)
class Admin::UserPresenter::CardTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — needs user_compliance_infos + comments(polymorphic) + memberships fixtures" do
    skip "TODO: migrate spec/presenters/admin/user_presenter/card_spec.rb (5 FB refs but wide surface; needs user_compliance_infos.yml + Comment polymorphic rows + stub helpers)"
  end
end
