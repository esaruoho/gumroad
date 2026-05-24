# frozen_string_literal: true

require "test_helper"

class Admin::SalesReportsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @admin_user = users(:admin_user)
    sign_in @admin_user
    @request.headers["X-Inertia"] = "true"
    GenerateSalesReportJob.jobs.clear
    @orig_protect = ActionController::Base.instance_method(:protect_against_forgery?)
    ActionController::Base.define_method(:protect_against_forgery?) { false }
  end

  teardown do
    ActionController::Base.define_method(:protect_against_forgery?, @orig_protect) if @orig_protect
  end

  test "inherits from Admin::BaseController" do
    assert_includes Admin::SalesReportsController.ancestors, Admin::BaseController
  end

  test "GET index renders the page" do
    job_history = '{"job_id":"123","country_code":"US","start_date":"2023-01-01","end_date":"2023-03-31","enqueued_at":"2023-01-01T00:00:00Z","status":"processing"}'
    # Stub $redis.lrange
    orig_lrange = $redis.method(:lrange)
    $redis.define_singleton_method(:lrange) do |key, *args|
      if key == RedisKey.sales_report_jobs && args == [0, 19]
        [job_history]
      else
        orig_lrange.call(key, *args)
      end
    end

    get :index
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal "Admin/SalesReports/Index", body["component"]
    props = body["props"]
    assert_equal "Sales reports", props["title"]
    assert_equal Compliance::Countries.for_select.map { |alpha2, name| [name, alpha2] }, props["countries"]
    assert_equal GenerateSalesReportJob::SALES_TYPES.map { |t| [t, t.humanize] }, props["sales_types"]
    assert_equal [JSON.parse(job_history)], props["job_history"]
    assert_predicate props["authenticity_token"], :present?
  ensure
    $redis.singleton_class.remove_method(:lrange) rescue nil
  end

  def create_params
    {
      sales_report: {
        country_code: "GB",
        start_date: "2023-01-01",
        end_date: "2023-03-31",
        sales_type: GenerateSalesReportJob::ALL_SALES
      }
    }
  end

  test "POST create enqueues a GenerateSalesReportJob with string dates" do
    post :create, params: create_params
    assert_equal 1, GenerateSalesReportJob.jobs.size
    assert_equal ["GB", "2023-01-01", "2023-03-31", GenerateSalesReportJob::ALL_SALES, true, nil],
                 GenerateSalesReportJob.jobs.last["args"]
  end

  test "POST create stores job details in Redis" do
    pushed = nil
    trimmed = nil
    $redis.define_singleton_method(:lpush) do |key, value|
      pushed = [key, value]
    end
    $redis.define_singleton_method(:ltrim) do |key, start, stop|
      trimmed = [key, start, stop]
    end
    post :create, params: create_params
    assert_equal RedisKey.sales_report_jobs, pushed[0]
    assert_equal [RedisKey.sales_report_jobs, 0, 19], trimmed
  ensure
    $redis.singleton_class.remove_method(:lpush) rescue nil
    $redis.singleton_class.remove_method(:ltrim) rescue nil
  end

  test "POST create 303 redirects to the sales reports page with a success message" do
    post :create, params: create_params
    assert_redirected_to admin_sales_reports_path
    assert_response :see_other
    assert_equal "Sales report job enqueued successfully!", flash[:notice]
  end

  test "POST create with invalid form 302 redirects with errors" do
    post :create, params: { sales_report: { country_code: "", start_date: "", end_date: "" } }
    assert_redirected_to admin_sales_reports_path
    assert_response :found
    assert_equal "Invalid form submission. Please fix the errors.", flash[:alert]
    expected_errors = {
      "sales_report.country_code" => "Please select a country",
      "sales_report.start_date" => "Invalid date format. Please use YYYY-MM-DD format",
      "sales_report.end_date" => "Invalid date format. Please use YYYY-MM-DD format",
      "sales_report.sales_type" => "Invalid sales type, should be all_sales or discover_sales."
    }
    assert_equal expected_errors, session[:inertia_errors]
  end
end
