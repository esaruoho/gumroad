# frozen_string_literal: true

require "test_helper"

class ServiceMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options
    { host: DOMAIN, protocol: PROTOCOL }
  end

  setup do
    @user = users(:service_mailer_user)
  end

  test "service_charge_receipt renders properly" do
    mail = ServiceMailer.service_charge_receipt(service_charges(:service_mailer_charge).id)
    assert_equal "Gumroad — Receipt", mail.subject
    assert_equal [@user.email], mail.to
    body = mail.body.to_s
    assert_includes body, "Thanks for continuing to support Gumroad!"
    assert_includes body, "you'll be charged at the same rate."
  end

  test "service_charge_receipt renders properly with discount code" do
    mail = ServiceMailer.service_charge_receipt(service_charges(:service_mailer_charge_with_discount).id)
    assert_equal "Gumroad — Receipt", mail.subject
    assert_equal [@user.email], mail.to
    body = mail.body.to_s
    assert_includes body, "Thanks for continuing to support Gumroad!"
    assert_includes body, "you'll be charged at the same rate."
    assert_includes body, "Credit applied:"
  end
end
