# frozen_string_literal: true

require "test_helper"

class SentryConfigurationTest < ActiveSupport::TestCase
  test "is not enabled in the test environment" do
    assert_equal false, Sentry.configuration.enabled_in_current_env?
  end

  test "only enables production and staging environments" do
    assert_equal %w[production staging], Sentry.configuration.enabled_environments
  end
end
