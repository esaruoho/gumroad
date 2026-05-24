# frozen_string_literal: true

require "test_helper"

# TODO: Migrate from RSpec. Skip-batched during fixtures-only controller migration.
# Original: spec/controllers/gumroad_blog/posts_controller_spec.rb (2 FactoryBot refs).
# Blocker: GumroadBlog::BaseController#set_blog_owner! calls
# User.find_by!(username: GlobalConfig.get("BLOG_OWNER_USERNAME", "gumroad")). The
# Minitest fixture set has no `gumroad`-username user. Adding one requires a new
# fixture row (and probably a profile row) that the policy and Inertia rendering
# paths depend on. Defer until the policy + Inertia rspec helpers have a clear
# Minitest equivalent — `inertia_rails/rspec` matchers don't have a 1:1 Minitest port.
class GumroadBlog::PostsControllerTest < ActiveSupport::TestCase
  test "TODO: migrate spec/controllers/gumroad_blog/posts_controller_spec.rb — needs gumroad-username fixture + Inertia rspec helper port" do
    skip "TODO: migrate spec/controllers/gumroad_blog/posts_controller_spec.rb (2 FB refs) — needs gumroad-username fixture + Pundit policy + Inertia rspec helper port"
  end
end
