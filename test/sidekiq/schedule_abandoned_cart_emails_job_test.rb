# frozen_string_literal: true

require "test_helper"

class ScheduleAbandonedCartEmailsJobTest < ActiveSupport::TestCase
  # The full job iterates Cart.abandoned, Workflow.alive.abandoned_cart_type.published,
  # and enqueues abandoned-cart emails per matched product. With no carts or
  # workflows in the fixture set, the job should complete cleanly without raising.

  test "completes without raising when there are no abandoned carts or workflows" do
    enqueued = []
    CustomerMailer.singleton_class.send(:remove_method, :abandoned_cart) if CustomerMailer.singleton_class.method_defined?(:abandoned_cart)
    CustomerMailer.define_singleton_method(:abandoned_cart) do |*args|
      m = Object.new
      m.define_singleton_method(:deliver_later) { |*_a, **_kw| enqueued << args }
      m
    end
    begin
      assert_nothing_raised do
        ScheduleAbandonedCartEmailsJob.new.perform
      end
    ensure
      CustomerMailer.singleton_class.send(:remove_method, :abandoned_cart) if CustomerMailer.singleton_class.method_defined?(:abandoned_cart)
    end
    assert_empty enqueued
  end
end
