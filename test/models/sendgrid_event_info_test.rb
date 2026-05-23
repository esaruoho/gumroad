# frozen_string_literal: true

require "test_helper"

class SendgridEventInfoTest < ActiveSupport::TestCase
  test "#for_abandoned_cart_email? returns true when mailer class is CustomerMailer and method is abandoned_cart" do
    event_json = { "mailer_class" => "CustomerMailer", "mailer_method" => "abandoned_cart" }
    assert_equal true, SendgridEventInfo.new(event_json).for_abandoned_cart_email?
  end

  test "#for_abandoned_cart_email? returns false when mailer class is not CustomerMailer" do
    event_json = { "mailer_class" => "CreatorContactingCustomersMailer", "mailer_method" => "abandoned_cart" }
    assert_equal false, SendgridEventInfo.new(event_json).for_abandoned_cart_email?
  end

  test "#for_abandoned_cart_email? returns false when mailer method is not abandoned_cart" do
    event_json = { "mailer_class" => "CustomerMailer", "mailer_method" => "purchase_installment" }
    assert_equal false, SendgridEventInfo.new(event_json).for_abandoned_cart_email?
  end
end
