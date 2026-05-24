# frozen_string_literal: true

require "test_helper"

class SubdomainTest < ActiveSupport::TestCase
  setup do
    @seller1 = users(:subdomain_seller_old_style) # username "test_user"
    @seller2 = users(:subdomain_seller_new_style) # username "testuser2subdomain"
    @seller3 = users(:subdomain_seller_no_username) # username nil
    @root_domain_without_port = URI("#{PROTOCOL}://#{ROOT_DOMAIN}").host
  end

  def request_obj(username)
    username = username.tr("_", "-")
    OpenStruct.new(host: "#{username}.#{@root_domain_without_port}", subdomains: [username])
  end

  def subdomain_url(username)
    [username.tr("_", "-"), @root_domain_without_port].join(".")
  end

  test "find_seller_by_request does not match sellers with blank usernames" do
    root_domain_request = OpenStruct.new(host: @root_domain_without_port, subdomains: [])
    assert_nil Subdomain.find_seller_by_request(root_domain_request)
  end

  test "find_seller_by_request finds the sellers using request subdomain" do
    assert_equal @seller1, Subdomain.find_seller_by_request(request_obj(@seller1.username))
    assert_equal @seller2, Subdomain.find_seller_by_request(request_obj(@seller2.username))
    assert_equal @seller3, Subdomain.find_seller_by_request(request_obj(@seller3.external_id))
  end

  test "find_seller_by_request does not find a deleted seller" do
    @seller1.mark_deleted!
    assert_nil Subdomain.find_seller_by_request(request_obj(@seller1.username))
  end

  test "find_seller_by_hostname does not match sellers with blank usernames" do
    assert_nil Subdomain.find_seller_by_hostname(@root_domain_without_port)
  end

  test "find_seller_by_hostname finds the sellers using request subdomain" do
    assert_equal @seller1, Subdomain.find_seller_by_hostname(subdomain_url(@seller1.username))
    assert_equal @seller2, Subdomain.find_seller_by_hostname(subdomain_url(@seller2.username))
  end

  test "find_seller_by_hostname does not find a deleted seller" do
    @seller1.mark_deleted!
    assert_nil Subdomain.find_seller_by_hostname(subdomain_url(@seller1.username))
  end

  test "subdomain_request? returns true when it's a valid subdomain request" do
    domain = "test.#{@root_domain_without_port}"
    assert Subdomain.send(:subdomain_request?, domain).present?
  end

  test "subdomain_request? returns false when hostname contains underscore" do
    domain = "test_123.#{@root_domain_without_port}"
    refute Subdomain.send(:subdomain_request?, domain).present?
  end

  test "subdomain_request? returns false when hostname doesn't look like a subdomain request" do
    domain = "sample.example.com"
    refute Subdomain.send(:subdomain_request?, domain).present?
  end
end
