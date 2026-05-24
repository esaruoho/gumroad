# frozen_string_literal: true

require "test_helper"

class RemoveDeletedFilesFromS3JobTest < ActiveSupport::TestCase
  # The job's CdnDeletable scope (s3.deleted.alive_in_cdn) filters on
  # url LIKE "#{S3_BASE_URL}%". The macOS/Minitest lane's S3_BASE_URL is
  # the local MinIO bucket, so we craft URLs with that prefix.
  def s3_url(name)
    "#{S3_BASE_URL}specs/#{name}-#{SecureRandom.hex(4)}.pdf"
  end

  setup do
    @job = RemoveDeletedFilesFromS3Job.new
    # Bypass S3 IO; assertions are on the deleted_from_cdn_at bookkeeping.
    @job.define_singleton_method(:delete_s3_objects!) { |_keys| nil }
  end

  test "removes recently deleted files from S3" do
    product = links(:named_seller_product)
    product_file = product.product_files.create!(url: s3_url("pf"), position: 99)
    product_file.update_columns(deleted_at: 26.hours.ago)
    archive = product.product_files_archives.create!(url: s3_url("arch"))
    archive.update_columns(deleted_at: 26.hours.ago)

    @job.perform

    assert_not_nil product_file.reload.deleted_from_cdn_at
    assert_not_nil archive.reload.deleted_from_cdn_at
  end

  test "does not remove older deleted files from S3" do
    product = links(:named_seller_product)
    pf = product.product_files.create!(url: s3_url("pf-old"), position: 100)
    pf.update_columns(deleted_at: 1.year.ago)
    @job.perform
    assert_nil pf.reload.deleted_from_cdn_at
  end

  test "does not remove files with existing alive duplicate files" do
    product = links(:named_seller_product)
    url = s3_url("dup")
    pf1 = product.product_files.create!(url: url, position: 101)
    pf1.update_columns(deleted_at: 26.hours.ago)
    product.product_files.create!(url: url, position: 102) # alive duplicate

    @job.perform
    assert_nil pf1.reload.deleted_from_cdn_at
  end

  test "notifies error tracker and continues when there's an error removing a file" do
    product = links(:named_seller_product)
    pf1 = product.product_files.create!(url: s3_url("err"), position: 103)
    pf2 = product.product_files.create!(url: s3_url("ok"), position: 104)
    [pf1, pf2].each { |f| f.update_columns(deleted_at: 26.hours.ago) }

    err_target_id = pf1.id
    original = @job.method(:remove_record_files)
    @job.define_singleton_method(:remove_record_files) do |file|
      raise RuntimeError, "boom" if file.id == err_target_id
      original.call(file)
    end

    notifications = []
    ErrorNotifier.stub(:notify, ->(e) { notifications << e }) do
      @job.perform
    end

    assert_equal 1, notifications.size
    assert_nil pf1.reload.deleted_from_cdn_at
    assert_not_nil pf2.reload.deleted_from_cdn_at
  end
end
