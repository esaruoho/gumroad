# frozen_string_literal: true

require_relative "test_helper"

# Proves the full stack boots: Puma serving the app, Playwright launched, a new
# context navigating to a real URL and reading the response back.
#
# Hits /healthcheck (plain text, no DB queries, no asset compilation) rather
# than / so this smoke test stays robust against unrelated app boot issues —
# its job is to prove the test harness is wired correctly, not to assert
# anything about the marketing homepage.
class SmokeTest < SystemTests::SystemTestCase
  def test_healthcheck_returns_ok
    response = page.goto(url_for("/healthcheck"))
    assert response, "page.goto returned nil"
    assert response.ok?, "expected 2xx from /healthcheck but got #{response.status}"
    assert_equal "healthcheck", page.evaluate("() => document.body.innerText").strip
  end
end
