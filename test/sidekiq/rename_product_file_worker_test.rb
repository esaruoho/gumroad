# frozen_string_literal: true

require "test_helper"

class RenameProductFileWorkerTest < ActiveSupport::TestCase
  test "renames the file when present in CDN" do
    file = product_files(:cdn_alive_file)
    called = false
    mod = Module.new
    mod.send(:define_method, :rename_in_storage) { called = true }
    ProductFile.prepend(mod)

    RenameProductFileWorker.new.perform(file.id)

    assert called
  ensure
    mod.module_eval { remove_method(:rename_in_storage) } if mod
  end

  test "does not rename the file when deleted from CDN" do
    file = product_files(:cdn_alive_file)
    file.mark_deleted_from_cdn
    called = false
    mod = Module.new
    mod.send(:define_method, :rename_in_storage) { called = true }
    ProductFile.prepend(mod)

    RenameProductFileWorker.new.perform(file.id)

    refute called
  ensure
    mod.module_eval { remove_method(:rename_in_storage) } if mod
  end
end
