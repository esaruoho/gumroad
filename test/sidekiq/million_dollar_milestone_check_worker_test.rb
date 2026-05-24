# frozen_string_literal: true

require "test_helper"

class MillionDollarMilestoneCheckWorkerTest < ActiveSupport::TestCase
  MILLION = MillionDollarMilestoneCheckWorker::MILLION_DOLLARS_IN_CENTS

  setup do
    @seller = users(:named_seller)
    @seller.update!(million_dollar_announcement_sent: false)
    @purchase = purchases(:named_seller_call_purchase)
    @purchase.update_columns(seller_id: @seller.id, created_at: 15.days.ago, purchase_state: "successful")

    @gross_returns = MILLION
    @compliance_returns = nil
    @update_returns = :real

    test_self = self

    User.class_eval do
      alias_method :_orig_gross_sales_cents_total_as_seller, :gross_sales_cents_total_as_seller
      alias_method :_orig_alive_user_compliance_info, :alive_user_compliance_info
      alias_method :_orig_update, :update

      define_method(:gross_sales_cents_total_as_seller) { test_self.instance_variable_get(:@gross_returns) }
      define_method(:alive_user_compliance_info) { test_self.instance_variable_get(:@compliance_returns) }
      define_method(:update) do |*args, **kwargs|
        ret = test_self.instance_variable_get(:@update_returns)
        ret == :real ? _orig_update(*args, **kwargs) : ret
      end
    end

    InternalNotificationWorker.clear
  end

  teardown do
    User.class_eval do
      remove_method :gross_sales_cents_total_as_seller
      remove_method :alive_user_compliance_info
      remove_method :update
      alias_method :gross_sales_cents_total_as_seller, :_orig_gross_sales_cents_total_as_seller
      alias_method :alive_user_compliance_info, :_orig_alive_user_compliance_info
      alias_method :update, :_orig_update
      remove_method :_orig_gross_sales_cents_total_as_seller
      remove_method :_orig_alive_user_compliance_info
      remove_method :_orig_update
    end
  end

  test "sends Slack notification if million dollar milestone is reached with no compliance info" do
    MillionDollarMilestoneCheckWorker.new.perform

    message = "<#{@seller.profile_url}|#{@seller.name_or_username}> has crossed $1M in earnings :tada:\n" \
              "• Name: #{@seller.name}\n" \
              "• Username: #{@seller.username}\n" \
              "• Email: #{@seller.email}\n"
    assert_includes InternalNotificationWorker.jobs.map { |j| j["args"] }, ["awards", "Gumroad Awards", message, "hotpink"]
  end

  test "sends Slack notification if million dollar milestone is reached with compliance info" do
    @compliance_returns = Struct.new(:first_name, :last_name, :street_address, :city, :state, :zip_code, :country)
                                .new("John", "Doe", "123 Main St", "San Francisco", "CA", "94105", "USA")

    MillionDollarMilestoneCheckWorker.new.perform

    message = "<#{@seller.profile_url}|#{@seller.name_or_username}> has crossed $1M in earnings :tada:\n" \
              "• Name: #{@seller.name}\n" \
              "• Username: #{@seller.username}\n" \
              "• Email: #{@seller.email}\n" \
              "• First name: John\n" \
              "• Last name: Doe\n" \
              "• Street address: 123 Main St\n" \
              "• City: San Francisco\n" \
              "• State: CA\n" \
              "• ZIP code: 94105\n" \
              "• Country: USA"
    assert_includes InternalNotificationWorker.jobs.map { |j| j["args"] }, ["awards", "Gumroad Awards", message, "hotpink"]
  end

  test "does not send Slack notification if million dollar milestone is not reached" do
    @gross_returns = 999_999

    MillionDollarMilestoneCheckWorker.new.perform

    assert_empty InternalNotificationWorker.jobs
  end

  test "does not send Slack notification if announcement has already been sent" do
    @seller.update!(million_dollar_announcement_sent: true)

    MillionDollarMilestoneCheckWorker.new.perform

    assert_empty InternalNotificationWorker.jobs
  end

  test "does not include users who have not made a sale in the last 3 weeks" do
    @purchase.update_columns(created_at: 4.weeks.ago)

    MillionDollarMilestoneCheckWorker.new.perform

    assert_empty InternalNotificationWorker.jobs
  end

  test "does not include users whose purchases are within the last 2 weeks" do
    @purchase.update_columns(created_at: 1.week.ago)

    MillionDollarMilestoneCheckWorker.new.perform

    assert_empty InternalNotificationWorker.jobs
  end

  test "marks seller as announcement sent" do
    MillionDollarMilestoneCheckWorker.new.perform

    assert_equal true, @seller.reload.million_dollar_announcement_sent
  end

  test "notifies error tracker if announcement cannot be marked as sent" do
    @update_returns = false
    notified = []
    err_mod = Module.new
    err_mod.send(:define_method, :notify) { |msg, **kwargs| notified << [msg, kwargs] }
    ErrorNotifier.singleton_class.prepend(err_mod)

    MillionDollarMilestoneCheckWorker.new.perform

    assert_includes notified, ["Failed to send Slack notification for million dollar milestone", { user_id: @seller.id }]
  end

  test "carries on with other users if announcement cannot be marked as sent for a user" do
    another_seller = users(:another_seller)
    another_seller.update!(million_dollar_announcement_sent: false)
    purchases(:another_seller_call_purchase).update_columns(
      seller_id: another_seller.id, created_at: 15.days.ago, purchase_state: "successful"
    )

    @update_returns = false
    notified = []
    err_mod = Module.new
    err_mod.send(:define_method, :notify) { |msg, **kwargs| notified << [msg, kwargs] }
    ErrorNotifier.singleton_class.prepend(err_mod)

    MillionDollarMilestoneCheckWorker.new.perform

    failures = notified.select { |msg, _| msg == "Failed to send Slack notification for million dollar milestone" }
    assert_equal 2, failures.size
  end
end
