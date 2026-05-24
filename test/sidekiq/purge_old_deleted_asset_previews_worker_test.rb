# frozen_string_literal: true

require "test_helper"

class PurgeOldDeletedAssetPreviewsWorkerTest < ActiveSupport::TestCase
  test "deletes targeted rows" do
    old = asset_previews(:deleted_old)
    recent = asset_previews(:deleted_recent)
    not_deleted = asset_previews(:not_deleted)

    original = PurgeOldDeletedAssetPreviewsWorker::DELETION_BATCH_SIZE
    PurgeOldDeletedAssetPreviewsWorker.send(:remove_const, :DELETION_BATCH_SIZE)
    PurgeOldDeletedAssetPreviewsWorker.const_set(:DELETION_BATCH_SIZE, 1)
    begin
      PurgeOldDeletedAssetPreviewsWorker.new.perform
    ensure
      PurgeOldDeletedAssetPreviewsWorker.send(:remove_const, :DELETION_BATCH_SIZE)
      PurgeOldDeletedAssetPreviewsWorker.const_set(:DELETION_BATCH_SIZE, original)
    end

    remaining_ids = AssetPreview.all.pluck(:id).sort
    assert_equal [recent.id, not_deleted.id].sort, remaining_ids
    refute AssetPreview.exists?(old.id)
  end
end
