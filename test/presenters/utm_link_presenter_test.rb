require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during mig-b presenter sweep.
# Blockers: requires :utm_link, :audience_post (:published trait), :workflow_installment
# fixture coverage — no test/fixtures/utm_links.yml or audience_posts/workflow_installments
# yet, and presenter aggregates utm_fields_values across all of them.
# Original spec: spec/presenters/utm_link_presenter_spec.rb (deleted; see git history)
class UtmLinkPresenterTest < ActiveSupport::TestCase
  test "TODO: migrate from RSpec — needs utm_links + audience_posts + workflow_installments fixtures" do
    skip "TODO: migrate spec/presenters/utm_link_presenter_spec.rb (12 FB refs; utm_links/audience_posts/workflow_installments fixture shape missing)"
  end
end
