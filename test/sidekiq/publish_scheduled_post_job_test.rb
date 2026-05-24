# frozen_string_literal: true

require "test_helper"

class PublishScheduledPostJobTest < ActiveSupport::TestCase
  setup do
    SendPostBlastEmailsJob.jobs.clear if SendPostBlastEmailsJob.respond_to?(:jobs)
    travel_to Time.current
    # Use an audience post (no link_id) with shown_on_profile + send_emails flags.
    # `published_at: nil` so the publish path runs.
    @post = Installment.create!(
      seller_id: users(:named_seller).id,
      name: "Scheduled Post",
      message: "Hello",
      slug: "scheduled-post-#{SecureRandom.hex(4)}",
      installment_type: Installment::AUDIENCE_TYPE,
      published_at: nil,
      shown_on_profile: true,
      send_emails: true,
    )
    @rule = InstallmentRule.create!(installment: @post, to_be_published_at: 1.hour.from_now)
  end

  teardown { travel_back }

  test "publishes post, creates a blast and enqueues SendPostBlastEmailsJob when send_emails? is true" do
    PublishScheduledPostJob.new.perform(@post.id, @rule.version)

    assert @post.reload.published?
    blast = PostEmailBlast.where(post: @post).last
    assert blast
    assert_equal @rule.to_be_published_at.to_i, blast.requested_at.to_i
    assert_includes SendPostBlastEmailsJob.jobs.map { |j| j["args"] }, [blast.id]
  end

  test "publishes post but does not create a blast when there was already one" do
    PostEmailBlast.create!(post: @post, requested_at: Time.current)
    assert_no_difference -> { PostEmailBlast.count } do
      PublishScheduledPostJob.new.perform(@post.id, @rule.version)
    end
    assert @post.reload.published?
    assert_empty SendPostBlastEmailsJob.jobs
  end

  test "publishes post but does not enqueue SendPostBlastEmailsJob when send_emails? is false" do
    @post.update!(send_emails: false)
    PublishScheduledPostJob.new.perform(@post.id, @rule.version)
    assert @post.reload.published?
    assert_empty SendPostBlastEmailsJob.jobs
  end

  test "does not publish post if the post is deleted" do
    @post.mark_deleted!
    PublishScheduledPostJob.new.perform(@post.id, @rule.version)
    refute @post.reload.published?
    assert_empty SendPostBlastEmailsJob.jobs
  end

  test "does not send emails if the post is already published" do
    @post.publish!
    PublishScheduledPostJob.new.perform(@post.id, @rule.version)
    assert @post.reload.published?
    assert_empty SendPostBlastEmailsJob.jobs
  end

  test "does not publish post if rule has a different version" do
    PublishScheduledPostJob.new.perform(@post.id, @rule.version + 1)
    refute @post.reload.published?
    assert_empty SendPostBlastEmailsJob.jobs
  end

  test "does not publish post if rule is deleted" do
    @rule.mark_deleted!
    PublishScheduledPostJob.new.perform(@post.id, @rule.version)
    refute @post.reload.published?
    assert_empty SendPostBlastEmailsJob.jobs
  end
end
