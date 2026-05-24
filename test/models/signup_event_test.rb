require "test_helper"

class SignupEventTest < ActiveSupport::TestCase
  test "is an Event" do
    event = SignupEvent.new(event_name: "signup", from_profile: false, ip_country: "United States", ip_state: "CA")
    assert_kind_of Event, event
  end
end
