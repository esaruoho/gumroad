# frozen_string_literal: true

require "test_helper"

class Integrations::DiscordIntegrationServiceTest < ActiveSupport::TestCase
  # Sharpened skip-stub.
  # Original: spec/services/integrations/discord_integration_service_spec.rb (510 lines, 45 FB refs)
  # Blocker: Discordrb::API::Server / API::User HTTP calls (WebMock stubs for resolve_member,
  # add_member_role, remove_member_role, server_members, roles); DiscordIntegration STI
  # fixture + product_integrations join + purchase + subscription chains; role-id arithmetic
  # across regular/admin/gumroad-bot/power-user. Defer until WebMock cassette translated.
  test "TODO: migrate spec/services/integrations/discord_integration_service_spec.rb" do
    skip "Fixture-hostile — Discord API WebMock stubs + Integration STI + purchase chain"
  end
end
