# frozen_string_literal: true

require "test_helper"

class CustomMailerRouteBuilderTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options
    { host: DOMAIN, protocol: PROTOCOL }
  end

  class TestMailer < ActionMailer::Base
    include CustomMailerRouteBuilder
  end

  setup do
    @mail = TestMailer.new
    @user = users(:named_seller)
    # Remove custom domain (user has user_domain_user_only) for the non-custom-domain cases.
    @user.custom_domain&.destroy
    @user.reload
    @post = installments(:published_post)
    # published_post is already shown_on_profile (flags: 128) and has slug "published-post-slug".
    # Build a purchase tied to the post's link. published_post has link_id: nil, so set one.
    @product = links(:named_seller_product)
    @post.update_column(:link_id, @product.id)
    @purchase = purchases(:audience_purchase)
  end

  test "returns nil when slug is missing" do
    @post.update_column(:slug, nil)
    assert_nil @mail.build_mailer_post_route(post: @post)
  end

  test "returns nil when not shown on profile" do
    @post.shown_on_profile = false
    @post.save!(validate: false)
    assert_nil @mail.build_mailer_post_route(post: @post)
  end

  test "returns view_post url when shown on profile and no custom domain" do
    url = "#{UrlService.domain_with_protocol}/#{@user.username}/p/#{@post.slug}"
    assert_equal url, @mail.build_mailer_post_route(post: @post)
  end

  test "appends purchase_id parameter when purchase is provided" do
    base = "#{UrlService.domain_with_protocol}/#{@user.username}/p/#{@post.slug}"
    expected = "#{base}?#{{ purchase_id: @purchase.external_id }.to_query}"
    assert_equal expected, @mail.build_mailer_post_route(post: @post, purchase: @purchase)
  end

  test "uses external_id when username is missing" do
    @user.update_column(:external_id, "extid_named_seller") if @user.external_id.blank?
    @user.update_columns(username: nil)
    url = "#{UrlService.domain_with_protocol}/#{@user.external_id}/p/#{@post.slug}"
    assert_equal url, @mail.build_mailer_post_route(post: @post)
  end

  test "uses custom_domain_view_post url when user has a custom domain" do
    domain = CustomDomain.create!(domain: "example.com", user: @user)
    @user.reload
    url = "http://#{domain.domain}/p/#{@post.slug}"
    assert_equal url, @mail.build_mailer_post_route(post: @post)
  end

  test "custom domain with purchase appends purchase_id" do
    domain = CustomDomain.create!(domain: "example.com", user: @user)
    @user.reload
    base = "http://#{domain.domain}/p/#{@post.slug}"
    expected = "#{base}?#{{ purchase_id: @purchase.external_id }.to_query}"
    assert_equal expected, @mail.build_mailer_post_route(post: @post, purchase: @purchase)
  end
end
