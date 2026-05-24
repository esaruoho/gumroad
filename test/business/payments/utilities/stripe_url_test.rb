# frozen_string_literal: true

require "test_helper"

class StripeUrlTest < ActiveSupport::TestCase
  test "dashboard_url returns production url when in production" do
    Rails.env.stub :production?, true do
      assert_equal "https://dashboard.stripe.com/1234/dashboard",
                   StripeUrl.dashboard_url(account_id: "1234")
    end
  end

  test "dashboard_url returns test url when not in production" do
    assert_equal "https://dashboard.stripe.com/1234/test/dashboard",
                 StripeUrl.dashboard_url(account_id: "1234")
  end

  test "event_url returns production url when in production" do
    Rails.env.stub :production?, true do
      assert_equal "https://dashboard.stripe.com/events/1234", StripeUrl.event_url("1234")
    end
  end

  test "event_url returns test url when not in production" do
    assert_equal "https://dashboard.stripe.com/test/events/1234", StripeUrl.event_url("1234")
  end
end
