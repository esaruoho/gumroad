require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during the bulk fixtures-only migration:
# JsErrorReporter is defined as a spec/support helper class, not in lib/. The
# spec exercises spec/support test infrastructure rather than production code,
# so it is out of scope for the spec/→test/ conversion (the support class would
# need to be ported first).
#
# Original spec: spec/lib/js_error_reporter_spec.rb (deleted in this commit; see git history)
class JsErrorReporterTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — spec/support class, out of scope" do
    skip "TODO: migrate spec/lib/js_error_reporter_spec.rb — JsErrorReporter is a spec/support helper, not a lib/ class"
  end
end
