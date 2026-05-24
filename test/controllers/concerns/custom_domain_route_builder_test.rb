# frozen_string_literal: true

require "test_helper"

class CustomDomainRouteBuilderTest < ActionController::TestCase
  class AnonymousController < ApplicationController
    include CustomDomainRouteBuilder
    def action
      head :ok
    end
  end

  tests AnonymousController

  include Devise::Test::ControllerHelpers

  setup do
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw { get "action" => "custom_domain_route_builder_test/anonymous#action" }
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @custom_domain = "store.example1.com"
  end

  test "#build_view_post_route returns custom_domain URL when request is from a custom domain" do
    post = installments(:published_post)
    purchase_external_id = "abcdef"
    @request.host = @custom_domain
    get :action
    result = @controller.build_view_post_route(post:, purchase_id: purchase_external_id)
    assert_match %r{/p/#{post.slug}.*purchase_id=#{purchase_external_id}}, result
  end

  test "#build_view_post_route returns view_post_path for non-custom domain" do
    post = installments(:published_post)
    purchase_external_id = "abc123"
    @request.host = DOMAIN
    get :action
    result = @controller.build_view_post_route(post:, purchase_id: purchase_external_id)
    assert_match %r{/p/#{post.slug}.*purchase_id=#{purchase_external_id}}, result
  end

  test "#seller_custom_domain_url returns root path for custom domain user" do
    user = users(:basic_user)
    user.update!(username: "examplecdu") unless user.username
    CustomDomain.create!(domain: @custom_domain, user: user)
    @request.host = @custom_domain
    get :action
    assert_equal "http://#{@custom_domain}/", @controller.seller_custom_domain_url
  end

  test "#seller_custom_domain_url returns nil for product custom domain" do
    product = links(:basic_user_product)
    CustomDomain.create!(domain: @custom_domain, product: product)
    @request.host = @custom_domain
    get :action
    assert_nil @controller.seller_custom_domain_url
  end

  test "#seller_custom_domain_url returns nil for non-custom-domain request" do
    @request.host = DOMAIN
    get :action
    assert_nil @controller.seller_custom_domain_url
  end
end
