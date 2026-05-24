# frozen_string_literal: true

require "test_helper"

class Admin::SalesReportTest < ActiveSupport::TestCase
  VALID_ATTRIBUTES = {
    country_code: "US",
    start_date: "2023-01-01",
    end_date: "2023-12-31",
    sales_type: GenerateSalesReportJob::ALL_SALES,
  }.freeze

  def valid_attributes
    VALID_ATTRIBUTES
  end

  setup do
    GenerateSalesReportJob.jobs.clear
  end

  # validations - country_code
  test "validations country_code is invalid when blank" do
    report = Admin::SalesReport.new(valid_attributes.merge(country_code: ""))
    assert_not report.valid?
    assert_includes report.errors[:country_code], "Please select a country"
  end

  test "validations country_code is valid when present" do
    assert Admin::SalesReport.new(valid_attributes).valid?
  end

  # validations - start_date
  test "validations start_date is invalid when blank" do
    report = Admin::SalesReport.new(valid_attributes.merge(start_date: ""))
    assert_not report.valid?
    assert_includes report.errors[:start_date], "Invalid date format. Please use YYYY-MM-DD format"
  end

  test "validations start_date is invalid when in the future" do
    report = Admin::SalesReport.new(valid_attributes.merge(start_date: 1.day.from_now.to_date))
    assert_not report.valid?
    assert_includes report.errors[:start_date], "cannot be in the future"
  end

  test "validations start_date is invalid when greater than or equal to end_date" do
    report = Admin::SalesReport.new(valid_attributes.merge(start_date: "2023-12-31", end_date: "2023-01-01"))
    assert_not report.valid?
    assert_includes report.errors[:start_date], "must be before end date"
  end

  test "validations start_date is valid when less than end_date" do
    assert Admin::SalesReport.new(valid_attributes).valid?
  end

  test "validations valid when start_date is today and end_date is in the future" do
    report = Admin::SalesReport.new(valid_attributes.merge(start_date: Date.current, end_date: Date.current + 1.day))
    assert report.valid?
  end

  # validations - end_date
  test "validations end_date is invalid when blank" do
    report = Admin::SalesReport.new(valid_attributes.merge(end_date: ""))
    assert_not report.valid?
    assert_includes report.errors[:end_date], "Invalid date format. Please use YYYY-MM-DD format"
  end

  test "validations end_date is valid when present" do
    assert Admin::SalesReport.new(valid_attributes).valid?
  end

  # date parsing - start_date=
  test "start_date= parses a valid date string in YYYY-MM-DD format" do
    report = Admin::SalesReport.new(start_date: "2023-01-15")
    assert_equal Date.new(2023, 1, 15), report.start_date
  end

  test "start_date= accepts a Date object" do
    date = Date.new(2023, 1, 15)
    report = Admin::SalesReport.new(start_date: date)
    assert_equal date, report.start_date
  end

  test "start_date= returns nil for invalid date string format" do
    assert_nil Admin::SalesReport.new(start_date: "01/15/2023").start_date
  end

  test "start_date= returns nil for unparseable date string" do
    assert_nil Admin::SalesReport.new(start_date: "2023-13-45").start_date
  end

  test "start_date= returns nil for blank value" do
    assert_nil Admin::SalesReport.new(start_date: "").start_date
  end

  # date parsing - end_date=
  test "end_date= parses a valid date string in YYYY-MM-DD format" do
    report = Admin::SalesReport.new(end_date: "2023-12-31")
    assert_equal Date.new(2023, 12, 31), report.end_date
  end

  test "end_date= accepts a Date object" do
    date = Date.new(2023, 12, 31)
    report = Admin::SalesReport.new(end_date: date)
    assert_equal date, report.end_date
  end

  test "end_date= returns nil for invalid date string format" do
    assert_nil Admin::SalesReport.new(end_date: "12/31/2023").end_date
  end

  test "end_date= returns nil for unparseable date string" do
    assert_nil Admin::SalesReport.new(end_date: "2023-13-45").end_date
  end

  test "end_date= returns nil for blank value" do
    assert_nil Admin::SalesReport.new(end_date: "").end_date
  end

  # accessor predicate methods
  test "country_code? returns true when country_code is present" do
    assert_equal true, Admin::SalesReport.new(country_code: "US").country_code?
  end

  test "country_code? returns false when country_code is blank" do
    assert_equal false, Admin::SalesReport.new(country_code: "").country_code?
  end

  test "start_date? returns true when start_date is present" do
    assert_equal true, Admin::SalesReport.new(start_date: "2023-01-01").start_date?
  end

  test "start_date? returns false when start_date is blank" do
    assert_equal false, Admin::SalesReport.new(start_date: "").start_date?
  end

  test "end_date? returns true when end_date is present" do
    assert_equal true, Admin::SalesReport.new(end_date: "2023-12-31").end_date?
  end

  test "end_date? returns false when end_date is blank" do
    assert_equal false, Admin::SalesReport.new(end_date: "").end_date?
  end

  # #generate_later
  test "#generate_later enqueues a GenerateSalesReportJob" do
    $redis.stub(:lpush, nil) do
      $redis.stub(:ltrim, nil) do
        Admin::SalesReport.new(valid_attributes).generate_later
      end
    end

    job = GenerateSalesReportJob.jobs.last
    assert_equal ["US", "2023-01-01", "2023-12-31", GenerateSalesReportJob::ALL_SALES, true, nil], job["args"]
  end

  test "#generate_later stores job details in Redis with the correct key" do
    lpush_args = nil
    ltrim_args = nil

    GenerateSalesReportJob.stub(:perform_async, "job_123") do
      $redis.stub(:lpush, ->(key, value) { lpush_args = [key, value] }) do
        $redis.stub(:ltrim, ->(key, a, b) { ltrim_args = [key, a, b] }) do
          Admin::SalesReport.new(valid_attributes).generate_later
        end
      end
    end

    assert_equal RedisKey.sales_report_jobs, lpush_args[0]
    assert_not_nil lpush_args[1]
    assert_equal [RedisKey.sales_report_jobs, 0, 19], ltrim_args
  end

  test "#generate_later stores job details with correct attributes" do
    captured_json = nil
    GenerateSalesReportJob.stub(:perform_async, "job_123") do
      $redis.stub(:lpush, ->(_key, json) { captured_json = json }) do
        $redis.stub(:ltrim, nil) do
          travel_to Time.new(2023, 1, 1, 12, 0, 0) do
            Admin::SalesReport.new(valid_attributes).generate_later
          end
        end
      end
    end

    data = JSON.parse(captured_json)
    assert_equal "job_123", data["job_id"]
    assert_equal "US", data["country_code"]
    assert_equal "2023-01-01", data["start_date"]
    assert_equal "2023-12-31", data["end_date"]
    assert_equal "all_sales", data["sales_type"]
    assert data["enqueued_at"].present?
    assert_equal "processing", data["status"]
  end

  test "#generate_later limits the job history to 20 items" do
    ltrim_args = nil
    GenerateSalesReportJob.stub(:perform_async, "job_123") do
      $redis.stub(:lpush, nil) do
        $redis.stub(:ltrim, ->(key, a, b) { ltrim_args = [key, a, b] }) do
          Admin::SalesReport.new(valid_attributes).generate_later
        end
      end
    end
    assert_equal [RedisKey.sales_report_jobs, 0, 19], ltrim_args
  end

  # .fetch_job_history
  def job_data
    [
      {
        job_id: "job_1",
        country_code: "US",
        start_date: "2023-01-01",
        end_date: "2023-03-31",
        sales_type: GenerateSalesReportJob::ALL_SALES,
        enqueued_at: "2023-01-01T00:00:00Z",
        status: "processing",
      }.to_json,
      {
        job_id: "job_2",
        country_code: "GB",
        start_date: "2023-04-01",
        end_date: "2023-06-30",
        sales_type: GenerateSalesReportJob::ALL_SALES,
        enqueued_at: "2023-04-01T00:00:00Z",
        status: "completed",
      }.to_json,
    ]
  end

  test ".fetch_job_history fetches and parses job history from Redis" do
    $redis.stub(:lrange, ->(_k, _a, _b) { job_data }) do
      result = Admin::SalesReport.fetch_job_history
      assert_kind_of Array, result
      assert_equal 2, result.size
      assert_equal "job_1", result[0]["job_id"]
      assert_equal "job_2", result[1]["job_id"]
    end
  end

  test ".fetch_job_history returns the last 20 jobs" do
    captured = nil
    $redis.stub(:lrange, ->(key, a, b) { captured = [key, a, b]; job_data }) do
      Admin::SalesReport.fetch_job_history
    end
    assert_equal [RedisKey.sales_report_jobs, 0, 19], captured
  end

  test ".fetch_job_history returns an empty array when Redis is empty" do
    $redis.stub(:lrange, ->(_k, _a, _b) { [] }) do
      assert_equal [], Admin::SalesReport.fetch_job_history
    end
  end

  test ".fetch_job_history returns an empty array when JSON parsing fails" do
    $redis.stub(:lrange, ->(_k, _a, _b) { ["invalid json"] }) do
      assert_equal [], Admin::SalesReport.fetch_job_history
    end
  end
end
