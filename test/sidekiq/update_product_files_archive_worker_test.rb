# frozen_string_literal: true

require "test_helper"

class UpdateProductFilesArchiveWorkerTest < ActiveSupport::TestCase
  # Real perform() returns immediately in Rails.env.test? (line 1 of perform).
  # We exercise that fast-path here; the heavy archive-build path requires
  # an S3/MinIO-backed ProductFilesArchive and is out of scope.

  test "returns early in test environment without raising" do
    assert_predicate Rails.env, :test?
    assert_nothing_raised do
      UpdateProductFilesArchiveWorker.new.perform(0)
    end
  end

  test "even with a bogus archive id, the test-env guard prevents the lookup" do
    # If the guard ever regresses, this id would trigger ActiveRecord::RecordNotFound.
    assert_nothing_raised do
      UpdateProductFilesArchiveWorker.new.perform(-1)
    end
  end
end
