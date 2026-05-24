# frozen_string_literal: true

require "test_helper"

class ActiveStorageAnalyzeJobErrorHandlingTest < ActiveSupport::TestCase
  test "discards the job when S3 returns NoSuchKey" do
    assert ActiveStorage::AnalyzeJob.rescue_handlers.any? { |handler| handler[0] == "Aws::S3::Errors::NoSuchKey" }
  end
end
