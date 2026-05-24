# frozen_string_literal: true

require "test_helper"

class AffiliateRequestMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options
    { host: DOMAIN, protocol: PROTOCOL }
  end

  setup do
    @seller = users(:named_seller)
    # Short-circuit User#mailer_level (Elasticsearch aggregations) for
    # MailerInfo.random_delivery_method_options(seller:).
    Rails.cache.write("creator_mailer_level_#{@seller.id}", :level_1)
  end

  # --- #notify_requester_of_request_submission ------------------------------

  test "notify_requester_of_request_submission sends email to requester" do
    request = affiliate_requests(:pending_request_to_named_seller)
    mail = AffiliateRequestMailer.notify_requester_of_request_submission(request.id)

    assert_equal [request.email], mail.to
    assert_equal "Your application request to #{@seller.display_name} was submitted!", mail.subject
    body = mail.body.encoded
    assert_includes body, "#{@seller.display_name} is now reviewing your application"
    assert_includes body, "<strong>Name:</strong> #{request.name}"
    assert_includes body, "<strong>Email:</strong> #{request.email}"
    assert_includes body, signup_url(email: request.email)
  end

  test "notify_requester_of_request_submission does not ask to create an account when requester already has one" do
    request = affiliate_requests(:pending_request_to_named_seller)
    # Reuse an existing user fixture by switching the request to that email.
    existing = users(:purchaser)
    request.update_column(:email, existing.email)
    mail = AffiliateRequestMailer.notify_requester_of_request_submission(request.id)
    refute_includes mail.body.encoded, "create your Gumroad account"
  end

  # --- #notify_requester_of_request_approval --------------------------------

  test "notify_requester_of_request_approval sends email to requester" do
    request = affiliate_requests(:approved_request_to_named_seller)
    # Need a User row matching the request's email so the mailer's find_by! succeeds.
    requester = users(:purchaser)
    request.update_column(:email, requester.email)
    mail = AffiliateRequestMailer.notify_requester_of_request_approval(request.id)

    assert_equal [requester.email], mail.to
    assert_equal "Your affiliate request to #{@seller.display_name} was approved!", mail.subject
    body = mail.body.encoded
    assert_includes body, "Congratulations, you are now an official affiliate for #{@seller.display_name}!"
    assert_includes body, "You can now promote these products using these unique URLs:"
    assert_includes body.gsub(/\s+/, " "), products_affiliated_index_url
  end

  # --- #notify_requester_of_ignored_request ---------------------------------

  test "notify_requester_of_ignored_request sends email to requester" do
    request = affiliate_requests(:ignored_request_to_named_seller)
    mail = AffiliateRequestMailer.notify_requester_of_ignored_request(request.id)

    assert_equal [request.email], mail.to
    assert_equal "Your affiliate request to #{@seller.display_name} was not approved", mail.subject
    body = mail.body.encoded
    assert_includes body, "We are sorry, but your request to become an affiliate for #{@seller.display_name} was not approved."
    assert_includes body, "<strong>Name:</strong> #{request.name}"
    assert_includes body, "<strong>Email:</strong> #{request.email}"
  end

  # --- #notify_unregistered_requester_of_request_approval -------------------

  test "notify_unregistered_requester_of_request_approval sends email to requester" do
    request = affiliate_requests(:approved_request_to_named_seller)
    mail = AffiliateRequestMailer.notify_unregistered_requester_of_request_approval(request.id)

    assert_equal [request.email], mail.to
    assert_equal "Your affiliate request to #{@seller.display_name} was approved!", mail.subject
    body = mail.body.encoded
    assert_includes body, "Congratulations, #{@seller.display_name} has approved your request to become an affiliate."
    assert_includes body, signup_url(email: request.email)
  end

  # --- #notify_seller_of_new_request ----------------------------------------

  test "notify_seller_of_new_request sends email to creator" do
    request = affiliate_requests(:pending_request_to_named_seller)
    mail = AffiliateRequestMailer.notify_seller_of_new_request(request.id)

    assert_equal [@seller.email], mail.to
    assert_equal "#{request.name} has applied to be an affiliate", mail.subject
    body = mail.body.encoded
    assert_includes body, "<strong>Name:</strong> #{request.name}"
    assert_includes body, "<strong>Email:</strong> #{request.email}"
    assert_includes body, approve_affiliate_request_url(request)
    assert_includes body, ignore_affiliate_request_url(request)
  end
end
