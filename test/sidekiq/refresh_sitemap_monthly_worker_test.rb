# frozen_string_literal: true

require "test_helper"

class RefreshSitemapMonthlyWorkerTest < ActiveSupport::TestCase
  setup do
    RefreshSitemapDailyWorker.clear
  end

  test "enqueues jobs to generate sitemaps for products updated in last month" do
    p3 = links(:sitemap_month_3)
    p2 = links(:sitemap_month_2)

    RefreshSitemapMonthlyWorker.new.perform

    months = [p3, p2].map { |p| p.created_at.beginning_of_month.to_date.to_s }
    enqueued_args = RefreshSitemapDailyWorker.jobs.map { |j| j["args"].first }
    assert_equal months.sort, enqueued_args.sort
  end

  test "doesn't enqueue jobs to generate sitemaps updated in the current month" do
    # Update all 'last-month' fixture products to created/updated now so they
    # fall outside the worker's last-month window.
    Link.where(id: [links(:sitemap_month_3).id, links(:sitemap_month_2).id])
        .update_all(updated_at: Time.current, created_at: Time.current)

    RefreshSitemapMonthlyWorker.new.perform

    assert_equal 0, RefreshSitemapDailyWorker.jobs.size
  end
end
