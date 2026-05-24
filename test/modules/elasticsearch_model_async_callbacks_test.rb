# frozen_string_literal: true

require "test_helper"

class ElasticsearchModelAsyncCallbacksTest < ActiveSupport::TestCase
  # The module under test relies on a real table being attached to the model,
  # and asserts on Sidekiq jobs enqueued during AR callbacks. Use a temporary
  # table built per-test, like the original spec.
  self.use_transactional_tests = false

  def create_mock_model
    name = "MockModel#{SecureRandom.hex(6)}"
    table_name = "#{name.tableize}_#{SecureRandom.hex}"
    model = Class.new(ApplicationRecord)
    model.define_singleton_method(:name) { name }
    model.table_name = table_name
    ActiveRecord::Base.connection.create_table(table_name, temporary: true) do |t|
      t.integer :user_id
      t.string :title
      t.string :subtitle
      t.timestamps null: false
    end
    model.belongs_to(:user, optional: true)
    Object.const_set(name, model) unless Object.const_defined?(name)
    model
  end

  def destroy_mock_model(model)
    ActiveRecord::Base.connection.drop_table(model.table_name, temporary: true, if_exists: true)
  ensure
    Object.send(:remove_const, model.name) if Object.const_defined?(model.name)
  end

  setup do
    ElasticsearchIndexerWorker.jobs.clear
    @model = create_mock_model
    @model.include(ElasticsearchModelAsyncCallbacks)
    @model.const_set("ATTRIBUTE_TO_SEARCH_FIELDS", "title" => "title")
    @multiplier = 2 # index/update queued twice for replica-lag mitigation
  end

  teardown do
    destroy_mock_model(@model) if @model
    ElasticsearchIndexerWorker.jobs.clear
  end

  def assert_job_enqueued(action, args)
    job = ElasticsearchIndexerWorker.jobs.find { |j| j["args"].first == action && args.all? { |k, v| j["args"][1][k.to_s] == v } }
    assert job, "expected an ElasticsearchIndexerWorker job with action=#{action.inspect} args=#{args.inspect}, got #{ElasticsearchIndexerWorker.jobs.inspect}"
  end

  test "record creation enqueues sidekiq job" do
    record = @model.create!(title: "original")

    assert_equal 1 * @multiplier, ElasticsearchIndexerWorker.jobs.size
    assert_job_enqueued("index", "record_id" => record.id, "class_name" => @model.name)
  end

  test "record creation enqueues sidekiq job even if no permitted value has changed" do
    record = @model.create!

    assert_equal 1 * @multiplier, ElasticsearchIndexerWorker.jobs.size
    assert_job_enqueued("index", "record_id" => record.id, "class_name" => @model.name)
  end

  test "record update enqueues sidekiq job" do
    record = @model.create!
    ElasticsearchIndexerWorker.jobs.clear

    record.update!(title: "new", subtitle: "new")

    assert_equal 1 * @multiplier, ElasticsearchIndexerWorker.jobs.size
    assert_job_enqueued("update", "record_id" => record.id, "fields" => ["title"], "class_name" => @model.name)
  end

  test "record update enqueues single sidekiq job when multiple attributes are saved separately in the same transaction" do
    record = @model.create!
    ElasticsearchIndexerWorker.jobs.clear

    @model::ATTRIBUTE_TO_SEARCH_FIELDS.merge!({ "subtitle" => "subtitle" })

    ApplicationRecord.transaction do
      record.update!(title: "new")
      record.update!(subtitle: "new")
    end

    assert_equal 1 * @multiplier, ElasticsearchIndexerWorker.jobs.size
    assert_job_enqueued("update", "record_id" => record.id, "fields" => ["title", "subtitle"], "class_name" => @model.name)
  end

  test "record update does not queue sidekiq jobs for ES indexing if no permitted column values have changed" do
    record = @model.create!
    ElasticsearchIndexerWorker.jobs.clear

    record.update!(user_id: 1)
    assert_empty ElasticsearchIndexerWorker.jobs

    record.update!(subtitle: "new")
    assert_equal 0, ElasticsearchIndexerWorker.jobs.size
  end

  test "record deletion queues sidekiq job" do
    record = @model.create!
    ElasticsearchIndexerWorker.jobs.clear

    record.destroy!

    assert_equal 1, ElasticsearchIndexerWorker.jobs.size
    assert_job_enqueued("delete", "record_id" => record.id, "class_name" => @model.name)
  end
end
