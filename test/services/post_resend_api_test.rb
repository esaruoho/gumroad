# frozen_string_literal: true

require "test_helper"

class PostResendApiTest < ActiveSupport::TestCase
  test "MAX_RECIPIENTS matches Resend batch limit" do
    assert_equal 100, PostResendApi::MAX_RECIPIENTS
  end

  test "initializer accepts post + recipients and seeds the cache per-post" do
    post = Object.new
    api = PostResendApi.new(post: post, recipients: [], cache: {})

    cache = api.instance_variable_get(:@cache)
    assert_equal({}, cache[post])
  end

  test "initializer preserves existing cache entries for the post" do
    post = Object.new
    seeded = { rendered_template: "X" }
    api = PostResendApi.new(post: post, recipients: [], cache: { post => seeded })

    cache = api.instance_variable_get(:@cache)
    assert_same seeded, cache[post]
  end

  test "preview and blast attributes default to safe values" do
    api = PostResendApi.new(post: Object.new, recipients: [])

    assert_equal false, api.instance_variable_get(:@preview)
    assert_nil api.instance_variable_get(:@blast)
  end

  test "#send_emails short-circuits to true for an empty recipient list" do
    api = PostResendApi.new(post: Object.new, recipients: [])

    assert_equal true, api.send_emails
  end

  # TODO: end-to-end batch+single send with Resend mocking (25 FB refs in the
  # original spec) renders the post via Premailer using seller_profile design,
  # product_files, url_redirects, CTAs, and audience_installments. That email
  # rendering chain is not portable to fixtures-only without a ProductFile
  # S3-backed fixture surface + view harness. Original:
  # spec/services/post_resend_api_spec.rb
end
