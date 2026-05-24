# frozen_string_literal: true

require "test_helper"

class MillionDollarMilestoneCheckWorkerTest < ActiveSupport::TestCase
  setup do
    @seller = users(:named_seller)
    # Ensure the worker's recent-purchase query picks this seller.
    @purchase = purchases(:million_dollar_recent_purchase)
    @seller.update!(million_dollar_announcement_sent: false)
    InternalNotificationWorker.jobs.clear
  end

  def with_user_stubs(gross_sales:, compliance_info: nil, update_returns: nil)
    mod = Module.new
    seller_id = @seller.id
    mod.send(:define_method, :gross_sales_cents_total_as_seller) do
      id == seller_id ? gross_sales : super()
    end
    mod.send(:define_method, :alive_user_compliance_info) do
      id == seller_id ? compliance_info : super()
    end
    if !update_returns.nil?
      mod.send(:define_method, :update) do |*args|
        id == seller_id ? update_returns : super(*args)
      end
    end
    User.prepend(mod)
    yield
  ensure
    mod.module_eval { instance_methods(false).each { |m| remove_method(m) } } if mod
  end

  def compliance_double(**attrs)
    o = Object.new
    o.define_singleton_method(:present?) { true }
    attrs.each { |k, v| o.define_singleton_method(k) { v } }
    o
  end

  test "sends Slack notification if million dollar milestone is reached with no compliance info" do
    with_user_stubs(gross_sales: 1_000_000_00, compliance_info: nil) do
      MillionDollarMilestoneCheckWorker.new.perform
    end

    message = "<#{@seller.profile_url}|#{@seller.name_or_username}> has crossed $1M in earnings :tada:\n" \
              "• Name: #{@seller.name}\n" \
              "• Username: #{@seller.username}\n" \
              "• Email: #{@seller.email}\n"

    job = InternalNotificationWorker.jobs.find { |j| j["args"].first == "awards" }
    assert job, "expected InternalNotificationWorker to be enqueued"
    assert_equal ["awards", "Gumroad Awards", message, "hotpink"], job["args"]
  end

  test "sends Slack notification if million dollar milestone is reached with compliance info" do
    info = compliance_double(
      first_name: "John", last_name: "Doe", street_address: "123 Main St",
      city: "San Francisco", state: "CA", zip_code: "94105", country: "USA"
    )

    with_user_stubs(gross_sales: 1_000_000_00, compliance_info: info) do
      MillionDollarMilestoneCheckWorker.new.perform
    end

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

    job = InternalNotificationWorker.jobs.find { |j| j["args"].first == "awards" }
    assert job
    assert_equal ["awards", "Gumroad Awards", message, "hotpink"], job["args"]
  end

  test "does not send Slack notification if million dollar milestone is not reached" do
    with_user_stubs(gross_sales: 999_999) do
      MillionDollarMilestoneCheckWorker.new.perform
    end

    assert_empty InternalNotificationWorker.jobs.select { |j| j["args"].first == "awards" }
  end

  test "does not send Slack notification if announcement has already been sent" do
    @seller.update!(million_dollar_announcement_sent: true)

    with_user_stubs(gross_sales: 1_000_000_00) do
      MillionDollarMilestoneCheckWorker.new.perform
    end

    assert_empty InternalNotificationWorker.jobs.select { |j| j["args"].first == "awards" }
  end

  test "does not include users whose recent purchases are outside the 3-week-to-2-week window" do
    @purchase.update_columns(created_at: 4.weeks.ago, succeeded_at: 4.weeks.ago)

    with_user_stubs(gross_sales: 1_000_000_00) do
      MillionDollarMilestoneCheckWorker.new.perform
    end

    assert_empty InternalNotificationWorker.jobs.select { |j| j["args"].first == "awards" }
  end

  test "does not include users whose purchases are within the last 2 weeks" do
    @purchase.update_columns(created_at: 1.week.ago, succeeded_at: 1.week.ago)

    with_user_stubs(gross_sales: 1_000_000_00) do
      MillionDollarMilestoneCheckWorker.new.perform
    end

    assert_empty InternalNotificationWorker.jobs.select { |j| j["args"].first == "awards" }
  end

  test "marks seller as announcement sent" do
    with_user_stubs(gross_sales: 1_000_000_00) do
      MillionDollarMilestoneCheckWorker.new.perform
    end

    assert_equal true, @seller.reload.million_dollar_announcement_sent
  end

  test "notifies error tracker if announcement cannot be marked as sent" do
    notify_args = []
    ErrorNotifier.stub(:notify, ->(msg, **kwargs) { notify_args << [msg, kwargs] }) do
      with_user_stubs(gross_sales: 1_000_000_00, update_returns: false) do
        MillionDollarMilestoneCheckWorker.new.perform
      end
    end

    assert notify_args.any? { |(msg, kwargs)|
      msg == "Failed to send Slack notification for million dollar milestone" && kwargs[:user_id] == @seller.id
    }
  end
end
