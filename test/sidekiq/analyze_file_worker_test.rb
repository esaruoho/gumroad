# frozen_string_literal: true

require "test_helper"

class AnalyzeFileWorkerTest < ActiveSupport::TestCase
  setup do
    @staging = ActiveSupport::StringInquirer.new("staging")
  end

  test "calls analyze for product file when no class name is provided" do
    product_file = product_files(:signed_url_helper_pdf)
    called = false
    ProductFile.define_method(:analyze) { called = true }
    Rails.stub(:env, @staging) do
      AnalyzeFileWorker.new.perform(product_file.id)
    end
    assert called
  ensure
    ProductFile.remove_method(:analyze) if ProductFile.instance_methods(false).include?(:analyze)
  end

  test "calls analyze for video files" do
    video_file = video_files(:named_seller_product_review_video_file)
    called = false
    VideoFile.define_method(:analyze) { called = true }
    Rails.stub(:env, @staging) do
      AnalyzeFileWorker.new.perform(video_file.id, VideoFile.name)
    end
    assert called
  ensure
    VideoFile.remove_method(:analyze) if VideoFile.instance_methods(false).include?(:analyze)
  end
end
