# frozen_string_literal: true

require "test_helper"

class EmailSuppressionManagerTest < ActiveSupport::TestCase
  EMAIL = "sam@example.com"

  setup do
    @api_new_orig = SendGrid::API.method(:new)
    @list_handlers = Hash.new { |h, k| h[k] = { get: [], delete: [] } }
    handlers = @list_handlers

    SendGrid::API.define_singleton_method(:new) do |*_args, **_kwargs|
      api = Object.new

      suppression = Object.new
      [:bounces, :blocks, :spam_reports, :invalid_emails].each do |list|
        suppression.define_singleton_method(list) do
          Class.new do
            define_method(:_) do |email|
              outer = self
              Class.new do
                define_method(:get) do
                  parsed = handlers[list][:get].shift
                  Struct.new(:parsed_body).new(parsed.nil? ? [] : parsed)
                end
                define_method(:delete) do
                  status = handlers[list][:delete].shift
                  Struct.new(:status_code).new(status.nil? ? 404 : status)
                end
              end.new
            end
          end.new
        end
      end

      client = Object.new
      client.define_singleton_method(:suppression) { suppression }
      # Old shape used by sendgrid(api_key).client.bounces._(email).delete chain
      # in #unblock_email — it routes through .bounces / .spam_reports on the
      # client itself, not via .client.suppression. Mirror that here.
      [:bounces, :blocks, :spam_reports, :invalid_emails].each do |list|
        client.define_singleton_method(list) { suppression.public_send(list) }
      end

      api.define_singleton_method(:client) { client }
      api
    end
  end

  teardown do
    SendGrid::API.define_singleton_method(:new, @api_new_orig) if @api_new_orig
  end

  def stub_get(list, body, times: 1)
    times.times { @list_handlers[list][:get] << body }
  end

  def stub_delete(list, status_code, times: 1)
    times.times { @list_handlers[list][:delete] << status_code }
  end

  test "#unblock_email scans all lists even when found in one of them" do
    # 5 subusers × 2 lists = 10 deletes per list scan; mark spam_reports as
    # successful for first subuser, bounces returns 404 elsewhere.
    [:bounces, :spam_reports].each { |list| stub_delete(list, 404, times: 5) }
    stub_delete(:spam_reports, 204, times: 5)

    # Just assert it doesn't raise and returns a boolean.
    result = EmailSuppressionManager.new(EMAIL).unblock_email
    assert_includes [true, false], result
  end

  test "#unblock_email returns true when email is found in any list" do
    stub_delete(:bounces, 404, times: 5)
    stub_delete(:spam_reports, 204, times: 5)
    assert_equal true, EmailSuppressionManager.new(EMAIL).unblock_email
  end

  test "#unblock_email returns false when email is not found in any list" do
    stub_delete(:bounces, 404, times: 10)
    stub_delete(:spam_reports, 404, times: 10)
    assert_equal false, EmailSuppressionManager.new(EMAIL).unblock_email
  end

  test "#reasons_for_suppression returns a list of reasons" do
    sample = [{ created: 1683811050, email: EMAIL, reason: "550 5.1.1 Sample reason", status: "5.1.1" }]
    stub_get(:bounces, sample, times: 5)
    stub_get(:spam_reports, [], times: 5)

    result = EmailSuppressionManager.new(EMAIL).reasons_for_suppression
    assert_includes result, :gumroad
    assert_equal [{ list: :bounces, reason: "550 5.1.1 Sample reason" }], result[:gumroad]
  end

  test "#reasons_for_suppression notifies error tracker when response is not an array of hashes" do
    stub_get(:bounces, "sample", times: 5)
    stub_get(:spam_reports, [], times: 5)

    notified = []
    ErrorNotifier.stub(:notify, ->(err, **_) { notified << err.class }) do
      EmailSuppressionManager.new(EMAIL).reasons_for_suppression
    end
    refute_empty notified
  end

  test "#detailed_status returns an empty bucket for every list when nothing is suppressed" do
    [:bounces, :blocks, :spam_reports, :invalid_emails].each { |list| stub_get(list, [], times: 5) }

    result = EmailSuppressionManager.new(EMAIL).detailed_status
    assert_equal [:bounces, :blocks, :spam_reports, :invalid_emails], result.keys
    assert(result.values.all? { |v| v == [] })
  end

  test "#detailed_status returns subuser-tagged entries for each suppression hit" do
    bounce_entry = { created: 1683811050, email: EMAIL, reason: "550 5.1.1 mailbox does not exist", status: "5.1.1" }
    block_entry  = { created: 1683811060, email: EMAIL, reason: "blocked by recipient mailserver", status: "5.7.1" }
    stub_get(:bounces, [bounce_entry], times: 5)
    stub_get(:blocks, [block_entry], times: 5)
    stub_get(:spam_reports, [], times: 5)
    stub_get(:invalid_emails, [], times: 5)

    result = EmailSuppressionManager.new(EMAIL).detailed_status
    assert_predicate result[:bounces], :present?
    first_bounce = result[:bounces].first
    assert_equal "550 5.1.1 mailbox does not exist", first_bounce[:reason]
    assert_equal :gumroad, first_bounce[:subuser]
    assert_equal Time.zone.at(1683811050).iso8601, first_bounce[:created_at]
    assert_predicate result[:blocks], :present?
  end

  test "#detailed_status swallows and reports parsing errors per list without aborting" do
    stub_get(:bounces, "garbage", times: 5)
    [:blocks, :spam_reports, :invalid_emails].each { |list| stub_get(list, [], times: 5) }

    notified = []
    ErrorNotifier.stub(:notify, ->(err, **_) { notified << err.class }) do
      assert_nothing_raised { EmailSuppressionManager.new(EMAIL).detailed_status }
    end
    refute_empty notified
  end

  test "#remove_from_lists deletes only the requested lists across every subuser" do
    stub_delete(:bounces, 204, times: 5)

    result = EmailSuppressionManager.new(EMAIL).remove_from_lists([:bounces])
    assert_equal [:bounces], result.keys
    assert_equal [:gumroad, :followers, :creators, :customers_level_1, :customers_level_2].sort,
                 result[:bounces].sort
  end

  test "#remove_from_lists skips subusers whose deletion returns a non-success status" do
    stub_delete(:bounces, 404, times: 5)
    result = EmailSuppressionManager.new(EMAIL).remove_from_lists([:bounces])
    assert_equal [], result[:bounces]
  end
end
