# frozen_string_literal: true

require "test_helper"

class CdnDeletableTest < ActiveSupport::TestCase
  test ".alive_in_cdn returns only records with deleted_from_cdn_at NULL" do
    alive_ids = ProductFile.alive_in_cdn.pluck(:id)
    assert_includes alive_ids, product_files(:cdn_alive_file).id
    refute_includes alive_ids, product_files(:cdn_already_deleted_from_cdn_file).id
  end

  test ".cdn_deletable only includes deleted records with S3 url alive in CDN" do
    alive = product_files(:cdn_alive_file)
    record_deleted_only = product_files(:cdn_record_deleted_only_file)
    both_deleted = product_files(:cdn_record_and_cdn_deleted_file)
    external_link = product_files(:cdn_deleted_external_link_file)

    ids = ProductFile.cdn_deletable.pluck(:id)
    assert_includes ids, record_deleted_only.id
    refute_includes ids, alive.id
    refute_includes ids, both_deleted.id
    refute_includes ids, external_link.id
  end

  test "#deleted_from_cdn? returns true when deleted_from_cdn_at is set" do
    assert_equal true, product_files(:cdn_already_deleted_from_cdn_file).deleted_from_cdn?
  end

  test "#deleted_from_cdn? returns false when deleted_from_cdn_at is NULL" do
    assert_equal false, product_files(:cdn_alive_file).deleted_from_cdn?
  end

  test "#mark_deleted_from_cdn sets deleted_from_cdn_at to current time" do
    product_file = product_files(:cdn_alive_file)
    travel_to(Time.current) do
      product_file.mark_deleted_from_cdn
      assert_equal Time.current.utc.to_s, product_file.deleted_from_cdn_at.to_s
    end
  end
end
