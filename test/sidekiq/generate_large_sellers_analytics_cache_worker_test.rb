# frozen_string_literal: true

require "test_helper"

class GenerateLargeSellersAnalyticsCacheWorkerTest < ActiveSupport::TestCase
  test "calls CreatorAnalytics::CachingProxy#generate_cache on each large seller" do
    expected_user_ids = [users(:basic_user).id, users(:named_seller).id].sort
    called_user_ids = []

    fake_proxy_class = Class.new do
      def initialize(user); @user = user; end
      attr_reader :user
      def generate_cache; end
    end

    CreatorAnalytics::CachingProxy.stub(:new, ->(user) {
      called_user_ids << user.id
      fake_proxy_class.new(user)
    }) do
      GenerateLargeSellersAnalyticsCacheWorker.new.perform
    end

    assert_equal expected_user_ids, called_user_ids.sort
  end

  test "rescues and reports errors per user, continuing iteration" do
    user_one = users(:basic_user)
    user_two = users(:named_seller)
    called_ids = []
    notified = []

    proxy_for = lambda do |user|
      if user.id == user_one.id
        raise "Something went wrong"
      else
        Object.new.tap do |o|
          o.define_singleton_method(:generate_cache) { called_ids << user.id }
        end
      end
    end

    ErrorNotifier.stub(:notify, ->(e, &_blk) { notified << e.message }) do
      CreatorAnalytics::CachingProxy.stub(:new, proxy_for) do
        GenerateLargeSellersAnalyticsCacheWorker.new.perform
      end
    end

    assert_includes notified, "Something went wrong"
    assert_includes called_ids, user_two.id
  end
end
