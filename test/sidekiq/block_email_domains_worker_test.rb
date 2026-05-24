# frozen_string_literal: true

require "test_helper"

class BlockEmailDomainsWorkerTest < ActiveSupport::TestCase
  test "blocks email domains without expiration" do
    admin = users(:admin_user)
    email_domains = ["example.com", "example.org"]

    assert_equal 0, PlatformBlock.email_domain.count

    BlockEmailDomainsWorker.new.perform(admin.id, email_domains)

    assert_equal 2, PlatformBlock.email_domain.count
    blocked = PlatformBlock.active.find_by(object_value: "example.com")
    assert_equal admin.id, blocked.blocked_by
    assert_nil blocked.expires_at
  end
end
