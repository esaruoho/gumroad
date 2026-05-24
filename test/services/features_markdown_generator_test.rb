# frozen_string_literal: true

require "test_helper"

class FeaturesMarkdownGeneratorTest < ActiveSupport::TestCase
  test "returns markdown containing all feature categories" do
    result = FeaturesMarkdownGenerator.call
    assert_includes result, "# Gumroad features"
    assert_includes result, "## Products"
    assert_includes result, "## Payments & checkout"
    assert_includes result, "## Payouts"
    assert_includes result, "## Content & delivery"
    assert_includes result, "## Profile & discovery"
    assert_includes result, "## Marketing & engagement"
    assert_includes result, "## Integrations"
    assert_includes result, "## Analytics & reporting"
    assert_includes result, "## Admin & developer tools"
    assert_includes result, "## Subscriptions & memberships"
  end

  test "includes the current date" do
    assert_includes FeaturesMarkdownGenerator.call, Date.current.strftime("%B %-d, %Y")
  end

  test "links to the features page" do
    assert_includes FeaturesMarkdownGenerator.call, "gumroad.com/features"
  end
end
