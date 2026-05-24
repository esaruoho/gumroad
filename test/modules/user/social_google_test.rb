# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration.
# Original: spec/modules/user/social_google_spec.rb (7 FactoryBot refs, 239 lines).
#
# Blocker for batch A backfill: every example exercises `User.find_or_create_for_google_oauth2`
# end-to-end (Omniauth payload → User.create!). `User.create!` is gated by `devise_pwned_password`,
# which hits `https://api.pwnedpasswords.com/range/...` and is blocked by the global
# `WebMock.disable_net_connect!` in `test/test_helper.rb`. The skill ref
# `leaf-backfill-pitfalls.md` documents this exact footgun: "User.create! → devise_pwned_password
# → real HTTP. Avoid ad-hoc User.create! in tests; use the rich fixture roster."
# The spec's whole point is that *creation* path though — fixture reuse does not help.
# Migration requires either stubbing PwnedPassword (mocha-heavy, banned) or bringing in a
# proper Devise.pwned_check WebMock harness. Out of scope for batch A.
class ModulesUserSocialGoogleTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — fixture-hostile, requires manual rewrite" do
    skip "TODO: migrate spec/modules/user/social_google_spec.rb — every example calls User.find_or_create_for_google_oauth2 which goes through devise_pwned_password → blocked WebMock; needs a pwnedpasswords stub harness."
  end
end
