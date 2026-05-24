# frozen_string_literal: true

require "test_helper"

class RefreshSitemapDailyWorkerTest < ActiveSupport::TestCase
  test "invokes SitemapService#generate" do
    called_with = []
    mod = Module.new
    mod.send(:define_method, :generate) { |*args| called_with << args }
    SitemapService.prepend(mod)

    RefreshSitemapDailyWorker.new.perform

    assert_equal 1, called_with.size
  ensure
    mod.module_eval { remove_method(:generate) } if mod
  end
end
