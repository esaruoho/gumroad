# frozen_string_literal: true

require "test_helper"

# The bulk of the InstallmentSearchService spec exercises actual ES indexing
# via `index_model_records(Installment)` and asserts on full-text results,
# which is out of scope for the Minitest lane (no live ES). The `.search`
# class method is a pure shortcut to `new(options).process`, which can be
# verified without standing up ES.
class InstallmentSearchServiceTest < ActiveSupport::TestCase
  test ".search is a shortcut to initialization + process" do
    captured = {}
    fake_instance = Object.new
    fake_instance.define_singleton_method(:process) { :result_sentinel }
    orig_new = InstallmentSearchService.method(:new)
    InstallmentSearchService.define_singleton_method(:new) do |opts|
      captured[:opts] = opts
      fake_instance
    end
    begin
      result = InstallmentSearchService.search(a: 1, b: 2)
    ensure
      InstallmentSearchService.define_singleton_method(:new, orig_new)
    end

    assert_equal({ a: 1, b: 2 }, captured[:opts])
    assert_equal :result_sentinel, result
  end

  # TODO: the full search/process behavior (seller filter, exclude_deleted,
  # type filter, exclude_workflow_installments, native ES params, fulltext)
  # depends on Elasticsearch + `index_model_records(Installment)`. Revisit
  # when an ES test harness is wired into the Minitest lane.
  # Original spec: spec/services/installment_search_service_spec.rb
end
