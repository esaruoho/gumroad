# frozen_string_literal: true

require "test_helper"

class VideoFileTest < ActiveSupport::TestCase
  setup do
    @user = users(:named_seller)
  end

  def build_video_file(attrs = {})
    VideoFile.new({
      user: @user,
      record: @user,
      url: "#{S3_BASE_URL}specs/ScreenRecording.mov",
      filetype: "mov",
    }.merge(attrs))
  end

  test "schedules a job to analyze the file after creation" do
    AnalyzeFileWorker.jobs.clear
    video_file = build_video_file
    video_file.save!
    job = AnalyzeFileWorker.jobs.last
    assert_not_nil job
    assert_equal [video_file.id, "VideoFile"], job["args"]
  end

  test "#url must start with S3_BASE_URL" do
    video_file = build_video_file
    video_file.url = "#{S3_BASE_URL}video.mp4"
    video_file.validate
    assert_empty video_file.errors[:url]

    video_file.url = "https://example.com/video.mp4"
    video_file.validate
    assert_includes video_file.errors[:url], "must be an S3 URL"
  end

  test "#smil_xml returns properly formatted SMIL XML with signed cloudfront URL" do
    s3_key = "attachments/1234567890abcdef1234567890abcdef/original/myvideo.mp4"
    s3_url = "#{S3_BASE_URL}#{s3_key}"
    signed_url = "https://cdn.example.com/signed-url-for-video.mp4"

    video_file = build_video_file(url: s3_url, filetype: "mp4")
    video_file.save!

    video_file.define_singleton_method(:signed_cloudfront_url) do |key, **opts|
      raise "unexpected args" unless key == s3_key && opts == { is_video: true }
      signed_url
    end

    expected_xml = %(<smil><body><switch><video src="#{signed_url}"/></switch></body></smil>)
    assert_equal expected_xml, video_file.smil_xml
  end

  test "#set_filetype sets filetype based on the file extension" do
    video_file = build_video_file(url: "#{S3_BASE_URL}video.mp4", filetype: nil)
    video_file.save!
    assert_equal "mp4", video_file.filetype

    video_file.update!(url: "#{S3_BASE_URL}video.mov")
    assert_equal "mov", video_file.filetype

    video_file.update!(url: "#{S3_BASE_URL}video.webm")
    assert_equal "webm", video_file.filetype
  end
end
