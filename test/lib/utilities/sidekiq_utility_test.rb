# frozen_string_literal: true

require "test_helper"

class SidekiqUtilityTest < ActiveSupport::TestCase
  def setup
    ENV["SIDEKIQ_GRACEFUL_SHUTDOWN_TIMEOUT"] = "3"
    ENV["SIDEKIQ_LIFECYCLE_HOOK_NAME"] = "sample_hook_name"
    ENV["SIDEKIQ_ASG_NAME"] = "sample_asg_name"

    @uri_double = Object.new
    @aws_instance_profile_double = Object.new
    @asg_double = Object.new

    # Stub out network/AWS calls before instantiating SidekiqUtility.
    @original_uri_parse = URI.method(:parse)
    URI.define_singleton_method(:parse) do |url|
      url == SidekiqUtility::INSTANCE_ID_ENDPOINT ? :uri_sentinel : URI::DEFAULT_PARSER.parse(url)
    end

    @original_http_get = Net::HTTP.method(:get)
    Net::HTTP.define_singleton_method(:get) do |arg|
      arg == :uri_sentinel ? "sample_instance_id" : raise("unexpected Net::HTTP.get #{arg.inspect}")
    end

    @original_credentials_new = Aws::InstanceProfileCredentials.method(:new)
    aws_creds_double = @aws_instance_profile_double
    Aws::InstanceProfileCredentials.define_singleton_method(:new) { |*_| aws_creds_double }

    @original_asg_client_new = Aws::AutoScaling::Client.method(:new)
    asg_dbl = @asg_double
    Aws::AutoScaling::Client.define_singleton_method(:new) { |**opts| asg_dbl }

    @current_time = Time.current
    travel_to(@current_time) do
      @sidekiq_utility = SidekiqUtility.new
    end
  end

  def teardown
    ENV.delete("SIDEKIQ_GRACEFUL_SHUTDOWN_TIMEOUT")
    ENV.delete("SIDEKIQ_LIFECYCLE_HOOK_NAME")
    ENV.delete("SIDEKIQ_ASG_NAME")

    URI.singleton_class.send(:remove_method, :parse) rescue nil
    URI.define_singleton_method(:parse, @original_uri_parse) if @original_uri_parse
    Net::HTTP.singleton_class.send(:remove_method, :get) rescue nil
    Net::HTTP.define_singleton_method(:get, @original_http_get) if @original_http_get
    Aws::InstanceProfileCredentials.singleton_class.send(:remove_method, :new) rescue nil
    Aws::InstanceProfileCredentials.define_singleton_method(:new, @original_credentials_new) if @original_credentials_new
    Aws::AutoScaling::Client.singleton_class.send(:remove_method, :new) rescue nil
    Aws::AutoScaling::Client.define_singleton_method(:new, @original_asg_client_new) if @original_asg_client_new
  end

  test "#initialize returns SidekiqUtility object with process_set and timeout_at variables" do
    assert_equal Sidekiq::ProcessSet, @sidekiq_utility.instance_variable_get(:@process_set).class
    assert_equal (@current_time + 3.hours).to_i, @sidekiq_utility.instance_variable_get(:@timeout_at).to_i
  end

  test "#instance_id returns the instance_id" do
    assert_equal "sample_instance_id", @sidekiq_utility.send(:instance_id)
  end

  test "#lifecycle_params returns lifecycle_params hash" do
    expected = {
      lifecycle_hook_name: "sample_hook_name",
      auto_scaling_group_name: "sample_asg_name",
      instance_id: "sample_instance_id",
    }
    assert_equal expected, @sidekiq_utility.send(:lifecycle_params)
  end

  test "#hostname returns hostname of the server" do
    assert_equal Socket.gethostname, @sidekiq_utility.send(:hostname)
  end

  test "#asg_client returns AWS Auto Scaling Group instance" do
    called_with = nil
    Aws::AutoScaling::Client.define_singleton_method(:new) do |**opts|
      called_with = opts
      :asg_returned
    end
    result = @sidekiq_utility.send(:asg_client)
    assert_equal :asg_returned, result
    assert_equal @aws_instance_profile_double, called_with[:credentials]
  end

  test "sidekiq_process returns the sidekiq process matching hostname" do
    process_set = [{ "hostname" => "test1" }, { "hostname" => "test2" }]
    @sidekiq_utility.define_singleton_method(:hostname) { "test1" }
    @sidekiq_utility.instance_variable_set(:@process_set, process_set)
    assert_equal "test1", @sidekiq_utility.send(:sidekiq_process)["hostname"]
  end

  test "proceed_with_instance_termination completes lifecycle action" do
    received_params = nil
    @asg_double.define_singleton_method(:complete_lifecycle_action) { |params| received_params = params }
    @sidekiq_utility.send(:proceed_with_instance_termination)
    expected = @sidekiq_utility.send(:lifecycle_params).merge(lifecycle_action_result: "CONTINUE")
    assert_equal expected, received_params
  end

  test "#timeout_exceeded? returns true if timeout is exceeded" do
    @sidekiq_utility.instance_variable_set(:@timeout_at, @current_time - 1.hour)
    assert @sidekiq_utility.send(:timeout_exceeded?)
  end

  test "#wait_for_sidekiq_to_process_existing_jobs: when timeout is exceeded, does not record heartbeat" do
    @sidekiq_utility.define_singleton_method(:sidekiq_process) { { "busy" => 2, "identity" => "test_identity" } }
    @sidekiq_utility.define_singleton_method(:timeout_exceeded?) { true }
    heartbeat_called = false
    @asg_double.define_singleton_method(:record_lifecycle_action_heartbeat) { |*| heartbeat_called = true }
    @sidekiq_utility.send(:wait_for_sidekiq_to_process_existing_jobs)
    refute heartbeat_called
  end

  test "#wait_for_sidekiq_to_process_existing_jobs: records heartbeat until timeout exceeds" do
    @sidekiq_utility.define_singleton_method(:sidekiq_process) { { "busy" => 2, "identity" => "test_identity" } }
    @sidekiq_utility.define_singleton_method(:sleep) { |*| }
    timeout_seq = [false, false, true]
    @sidekiq_utility.define_singleton_method(:timeout_exceeded?) { timeout_seq.shift }
    heartbeat_calls = 0
    @asg_double.define_singleton_method(:record_lifecycle_action_heartbeat) { |*| heartbeat_calls += 1 }
    @sidekiq_utility.send(:wait_for_sidekiq_to_process_existing_jobs)
    assert_equal 2, heartbeat_calls
  end

  test "#wait_for_sidekiq_to_process_existing_jobs: when all jobs are ignored classes, logs and breaks the loop" do
    @sidekiq_utility.define_singleton_method(:sidekiq_process) { { "busy" => 2, "identity" => "test_identity" } }
    @sidekiq_utility.define_singleton_method(:timeout_exceeded?) { false }
    workers = [["test_identity", "worker1", { "payload" => { "class" => "HandleSendgridEventJob" }.to_json }]]
    Sidekiq::Workers.define_singleton_method(:new) { workers }
    logged_msgs = []
    Rails.logger.stub(:info, ->(msg) { logged_msgs << msg }) do
      heartbeat_called = false
      @asg_double.define_singleton_method(:record_lifecycle_action_heartbeat) { |*| heartbeat_called = true }
      @sidekiq_utility.send(:wait_for_sidekiq_to_process_existing_jobs)
      refute heartbeat_called
    end
    assert_includes logged_msgs, "[SidekiqUtility] HandleSendgridEventJob jobs are stuck. Proceeding with instance termination."
  ensure
    Sidekiq::Workers.singleton_class.send(:remove_method, :new) rescue nil
  end

  test "#wait_for_sidekiq_to_process_existing_jobs: when not all jobs are ignored, continues and records heartbeat" do
    @sidekiq_utility.define_singleton_method(:sidekiq_process) { { "busy" => 2, "identity" => "test_identity" } }
    workers = [
      ["test_identity", "worker1", { "payload" => { "class" => "HandleSendgridEventJob" }.to_json }],
      ["test_identity", "worker1", { "payload" => { "class" => "OtherJob" }.to_json }]
    ]
    Sidekiq::Workers.define_singleton_method(:new) { workers }
    @sidekiq_utility.define_singleton_method(:sleep) { |*| }
    timeout_seq = [false, true]
    @sidekiq_utility.define_singleton_method(:timeout_exceeded?) { timeout_seq.shift }
    heartbeat_calls = 0
    @asg_double.define_singleton_method(:record_lifecycle_action_heartbeat) { |*| heartbeat_calls += 1 }
    stuck_msg_logged = false
    Rails.logger.stub(:info, ->(msg) { stuck_msg_logged = true if msg.to_s.include?("are stuck") }) do
      @sidekiq_utility.send(:wait_for_sidekiq_to_process_existing_jobs)
    end
    refute stuck_msg_logged
    assert_equal 1, heartbeat_calls
  ensure
    Sidekiq::Workers.singleton_class.send(:remove_method, :new) rescue nil
  end

  test "#stop_process sets the process to quiet, waits for jobs, and proceeds with termination" do
    quiet_called = false
    wait_called = false
    proceed_called = false
    sidekiq_process_double = Object.new
    sidekiq_process_double.define_singleton_method(:quiet!) { quiet_called = true }
    @sidekiq_utility.define_singleton_method(:sidekiq_process) { sidekiq_process_double }
    @sidekiq_utility.define_singleton_method(:wait_for_sidekiq_to_process_existing_jobs) { wait_called = true }
    @sidekiq_utility.define_singleton_method(:proceed_with_instance_termination) { proceed_called = true }
    @sidekiq_utility.stop_process
    assert quiet_called
    assert wait_called
    assert proceed_called
  end
end
