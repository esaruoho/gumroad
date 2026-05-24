# frozen_string_literal: true

require "test_helper"

class HandleGrmcCallbackJobTest < ActiveSupport::TestCase
  setup do
    @transcoded_video = transcoded_videos(:grmc_callback_processing)
    @transcoded_video_dup = transcoded_videos(:grmc_callback_processing_dup)
    @product_file = @transcoded_video.streamable
    @product_file_dup = @transcoded_video_dup.streamable
  end

  test "marks transcoded video completed and flips product file on success" do
    notification = { "job_id" => @transcoded_video.job_id, "status" => "success" }

    HandleGrmcCallbackJob.new.perform(notification)

    assert @product_file.reload.is_transcoded_for_hls
    assert_equal "/attachments/68756f28973n28347/hls/index.m3u8", @transcoded_video.reload.transcoded_video_key
    assert_equal "completed", @transcoded_video.state
  end

  test "updates all matching processing transcoded_videos on success" do
    notification = { "job_id" => @transcoded_video.job_id, "status" => "success" }

    HandleGrmcCallbackJob.new.perform(notification)

    assert @product_file.reload.is_transcoded_for_hls
    assert_equal "completed", @transcoded_video.reload.state
    assert @product_file_dup.reload.is_transcoded_for_hls
    assert_equal "completed", @transcoded_video_dup.reload.state
    assert_equal "/attachments/68756f28973n28347/hls/index.m3u8", @transcoded_video_dup.transcoded_video_key
  end

  test "enqueues TranscodeVideoForStreamingWorker on failure status" do
    notification = { "job_id" => @transcoded_video.job_id, "status" => "failure" }

    TranscodeVideoForStreamingWorker.jobs.clear
    HandleGrmcCallbackJob.new.perform(notification)

    job_args = TranscodeVideoForStreamingWorker.jobs.map { |j| j["args"] }
    assert_includes job_args, [@product_file.id, ProductFile.name, TranscodeVideoForStreamingWorker::MEDIACONVERT, true]
  end

  test "marks the transcoded video as errored on failure status" do
    notification = { "job_id" => @transcoded_video.job_id, "status" => "failure" }

    HandleGrmcCallbackJob.new.perform(notification)

    assert_equal "error", @transcoded_video.reload.state
  end
end
