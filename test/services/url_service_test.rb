# frozen_string_literal: true

require "test_helper"

class UrlServiceTest < ActiveSupport::TestCase
  test "#domain_with_protocol returns domain with protocol" do
    assert_equal "#{PROTOCOL}://#{DOMAIN}", UrlService.domain_with_protocol
  end

  test "#api_domain_with_protocol returns domain with protocol" do
    assert_equal "#{PROTOCOL}://#{API_DOMAIN}", UrlService.api_domain_with_protocol
  end

  test "#short_domain_with_protocol returns short domain with protocol" do
    assert_equal "#{PROTOCOL}://#{SHORT_DOMAIN}", UrlService.short_domain_with_protocol
  end

  test "#root_domain_with_protocol returns root_domain with protocol" do
    assert_equal "#{PROTOCOL}://#{ROOT_DOMAIN}", UrlService.root_domain_with_protocol
  end

  test "#discover_domain_with_protocol returns path with protocol and domain" do
    assert_equal "#{PROTOCOL}://#{DISCOVER_DOMAIN}", UrlService.discover_domain_with_protocol
  end

  test "#discover_full_path returns path with protocol and domain" do
    assert_equal "#{PROTOCOL}://#{DISCOVER_DOMAIN}/3d", UrlService.discover_full_path("/3d")
  end

  test "#discover_full_path returns path and query with protocol and domain" do
    assert_equal "#{PROTOCOL}://#{DISCOVER_DOMAIN}/3d?tags=tag-1",
                 UrlService.discover_full_path("/3d", { tags: "tag-1" })
  end

  # widget_product_link_base_url ---------------------------------------------

  test "widget_product_link_base_url returns root domain when no user specified" do
    assert_equal UrlService.root_domain_with_protocol, UrlService.widget_product_link_base_url
  end

  test "widget_product_link_base_url returns root domain when user has no username or custom domain" do
    # User without username/custom_domain — note the seller arg isn't passed here
    # to mirror original RSpec (it actually passes no seller too).
    assert_equal UrlService.root_domain_with_protocol, UrlService.widget_product_link_base_url
  end

  test "widget_product_link_base_url returns user's subdomain URL when user has no custom domain" do
    user = users(:url_service_user_with_username)
    assert_equal user.subdomain_with_protocol,
                 UrlService.widget_product_link_base_url(seller: user)
  end

  test "widget_product_link_base_url returns user's subdomain URL when user has inactive custom domain" do
    user = users(:url_service_user_inactive_cd)
    # Sanity: inactive custom domain is not active?
    assert_not user.custom_domain.active?
    assert_equal user.subdomain_with_protocol,
                 UrlService.widget_product_link_base_url(seller: user)
  end

  test "widget_product_link_base_url returns subdomain when active custom domain doesn't strictly point to gumroad" do
    user = users(:url_service_user_active_cd)
    cd = user.custom_domain
    with_custom_domain_verification(cd.domain, ["example.com"]) do
      assert_equal user.subdomain_with_protocol,
                   UrlService.widget_product_link_base_url(seller: user)
    end
  end

  test "widget_product_link_base_url returns custom domain with protocol when domain matches" do
    user = users(:url_service_user_active_cd)
    cd = user.custom_domain
    with_custom_domain_verification(cd.domain, [cd.domain]) do
      assert_equal "#{PROTOCOL}://#{cd.domain}",
                   UrlService.widget_product_link_base_url(seller: user)
    end
  end

  # widget_script_base_url ---------------------------------------------------

  test "widget_script_base_url returns root domain when no user specified" do
    assert_equal UrlService.root_domain_with_protocol, UrlService.widget_script_base_url
  end

  test "widget_script_base_url returns root domain when user has no custom domain" do
    user = users(:url_service_user_with_username)
    assert_equal UrlService.root_domain_with_protocol,
                 UrlService.widget_script_base_url(seller: user)
  end

  test "widget_script_base_url returns root domain when user has inactive custom domain" do
    user = users(:url_service_user_inactive_cd)
    assert_equal UrlService.root_domain_with_protocol,
                 UrlService.widget_script_base_url(seller: user)
  end

  test "widget_script_base_url returns root domain when active custom domain doesn't point to gumroad" do
    user = users(:url_service_user_active_cd)
    cd = user.custom_domain
    with_custom_domain_verification(cd.domain, ["example.com"]) do
      assert_equal UrlService.root_domain_with_protocol,
                   UrlService.widget_script_base_url(seller: user)
    end
  end

  test "widget_script_base_url returns custom domain with protocol when domain matches" do
    user = users(:url_service_user_active_cd)
    cd = user.custom_domain
    with_custom_domain_verification(cd.domain, [cd.domain]) do
      assert_equal "#{PROTOCOL}://#{cd.domain}",
                   UrlService.widget_script_base_url(seller: user)
    end
  end

  private
    # Stub CustomDomainVerificationService.new(domain:) so it returns a fake
    # whose #domains_pointed_to_gumroad returns the supplied array.
    def with_custom_domain_verification(domain, pointed_to)
      fake = Object.new
      fake.define_singleton_method(:domains_pointed_to_gumroad) { pointed_to }
      original = CustomDomainVerificationService.method(:new)
      CustomDomainVerificationService.define_singleton_method(:new) do |**kwargs|
        kwargs[:domain] == domain ? fake : original.call(**kwargs)
      end
      yield
    ensure
      CustomDomainVerificationService.singleton_class.send(:remove_method, :new) rescue nil
      CustomDomainVerificationService.define_singleton_method(:new, original) if original
    end
end
