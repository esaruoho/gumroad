# frozen_string_literal: true

require "test_helper"

class EventTest < ActiveSupport::TestCase
  setup do
    @post = installments(:published_post)
    @post_view_event = Event.create!(event_name: "post_view")
    @installment_event = InstallmentEvent.create!(event_id: @post_view_event.id, installment_id: @post.id)
  end

  test "creates the post_view event with the right values" do
    assert_equal "post_view", @post_view_event.event_name
    assert_equal @post.id, @installment_event.installment_id
    assert_equal @post_view_event.id, @installment_event.event_id
  end

  test "is counted for in the post_view scope" do
    assert_equal 1, Event.post_view.count
  end
end
