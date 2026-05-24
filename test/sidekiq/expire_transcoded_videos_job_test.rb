# frozen_string_literal: true

require "test_helper"

class ExpireTranscodedVideosJobTest < ActiveSupport::TestCase
  test "marks old transcoded videos as deleted" do
    $redis.set(RedisKey.transcoded_videos_recentness_limit_in_months, 3)

    nil_tv = transcoded_videos(:transcoded_video_nil_last_accessed)
    # The fixture row carries an explicit last_accessed_at because we cannot
    # bypass the before_save default in YAML; clear it back to nil here.
    nil_tv.update_column(:last_accessed_at, nil)

    recent_tv = transcoded_videos(:transcoded_video_recent)
    old_tv = transcoded_videos(:transcoded_video_old)

    ExpireTranscodedVideosJob.new.perform

    refute nil_tv.reload.deleted?
    assert nil_tv.streamable.reload.is_transcoded_for_hls?

    refute recent_tv.reload.deleted?
    assert recent_tv.streamable.reload.is_transcoded_for_hls?

    assert old_tv.reload.deleted?
    refute old_tv.streamable.reload.is_transcoded_for_hls?
  ensure
    $redis.del(RedisKey.transcoded_videos_recentness_limit_in_months)
  end
end
