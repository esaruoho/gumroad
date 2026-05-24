# frozen_string_literal: true

require "test_helper"

class SendYearInReviewEmailJobTest < ActiveSupport::TestCase
  setup do
    @user = users(:named_seller)
  end

  test "returns early when seller has no payout_csv_url for the year" do
    User.define_method(:financial_annual_report_url_for) { |**_kw| nil }
    sent = []
    CreatorMailer.singleton_class.send(:remove_method, :year_in_review) if CreatorMailer.singleton_class.method_defined?(:year_in_review)
    CreatorMailer.define_singleton_method(:year_in_review) do |*_a, **_kw|
      m = Object.new; m.define_singleton_method(:deliver_later) { |*_, **__| sent << :y }; m
    end
    begin
      SendYearInReviewEmailJob.new.perform(@user.id, 2023)
    ensure
      User.remove_method(:financial_annual_report_url_for) if User.method_defined?(:financial_annual_report_url_for)
      CreatorMailer.singleton_class.send(:remove_method, :year_in_review) if CreatorMailer.singleton_class.method_defined?(:year_in_review)
    end
    assert_empty sent
  end

  test "returns early when analytics totals net to zero (affiliate-only earnings)" do
    User.define_method(:financial_annual_report_url_for) { |**_kw| "http://s3/csv" }
    fake_caching_proxy = Object.new
    fake_caching_proxy.define_singleton_method(:data_for_dates) do |_begin, _end, by:|
      if by == :date
        { by_date: { views: {}, sales: {}, totals: {} } }
      else
        { by_state: {} }
      end
    end
    CreatorAnalytics::CachingProxy.stub(:new, ->(_u) { fake_caching_proxy }) do
      sent = []
      CreatorMailer.singleton_class.send(:remove_method, :year_in_review) if CreatorMailer.singleton_class.method_defined?(:year_in_review)
      CreatorMailer.define_singleton_method(:year_in_review) do |*_a, **_kw|
        m = Object.new; m.define_singleton_method(:deliver_later) { |*_, **__| sent << :y }; m
      end
      begin
        SendYearInReviewEmailJob.new.perform(@user.id, 2023)
      ensure
        CreatorMailer.singleton_class.send(:remove_method, :year_in_review) if CreatorMailer.singleton_class.method_defined?(:year_in_review)
        User.remove_method(:financial_annual_report_url_for) if User.method_defined?(:financial_annual_report_url_for)
      end
      assert_empty sent
    end
  end
end
