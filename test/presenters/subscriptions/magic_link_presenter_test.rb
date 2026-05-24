# frozen_string_literal: true

require "test_helper"

class Subscriptions::MagicLinkPresenterTest < ActiveSupport::TestCase
  setup do
    @subscription = subscriptions(:magic_link_subscription)
    @user = users(:magic_link_user)
  end

  test "#magic_link_props returns the right props" do
    result = Subscriptions::MagicLinkPresenter.new(subscription: @subscription).magic_link_props

    assert_equal @subscription.external_id, result[:subscription_id]
    assert_equal false, result[:is_installment_plan]
    assert_equal "Test product name", result[:product_name]

    emails = result[:user_emails]
    assert_equal 2, emails.size

    user_email_entry = emails.find { |e| e[:email] == EmailRedactorService.redact("user@email.com") }
    refute_nil user_email_entry, "expected user@email.com to be present"
    assert_includes [:subscription, :user], user_email_entry[:source]

    purchase_email_entry = emails.find { |e| e[:email] == EmailRedactorService.redact("purchase@email.com") }
    refute_nil purchase_email_entry, "expected purchase@email.com to be present"
    assert_equal :purchase, purchase_email_entry[:source]
  end
end
