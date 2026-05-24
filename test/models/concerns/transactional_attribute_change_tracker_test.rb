require "test_helper"

class TransactionalAttributeChangeTrackerTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def create_mock_model
    name = "TacMock#{SecureRandom.hex(4)}"
    table_name = "tac_mock_#{SecureRandom.hex(6)}"
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
    @model = create_mock_model
    @model.include(TransactionalAttributeChangeTracker)
    @record = @model.create!
  end

  teardown do
    destroy_mock_model(@model) if @model
  end

  test "#attributes_committed returns nil if no attribute changes were committed" do
    fresh = @model.find(@record.id)
    assert_nil fresh.attributes_committed

    fresh.title = "foo"
    assert_nil fresh.attributes_committed
  end

  test "#attributes_committed returns attributes changed in the transaction when record was created" do
    assert_equal %w[id created_at updated_at].sort, @record.attributes_committed.sort
  end

  test "#attributes_committed returns attributes changed in the transaction when record was updated" do
    @record.update!(title: "foo", subtitle: "bar")
    assert_equal %w[title subtitle updated_at].sort, @record.attributes_committed.sort
  end

  test "#attributes_committed only returns attributes changed in the transaction when record was last updated" do
    @record.update!(title: "foo")
    assert_equal %w[title updated_at].sort, @record.attributes_committed.sort

    @record.update!(subtitle: "bar")
    assert_equal %w[subtitle updated_at].sort, @record.attributes_committed.sort
  end

  test "#attributes_committed returns attributes changed in the transaction when record was updated several times" do
    assert_nil @record.title

    ApplicationRecord.transaction do
      @record.update!(title: "foo")
      @record.update!(subtitle: "bar")
      @record.update!(user_id: 1)
      @record.update!(title: nil)
    end
    assert_equal %w[title subtitle user_id updated_at].sort, @record.attributes_committed.sort
  end

  test "#attributes_committed returns attributes changed in the transaction when record was updated and reloaded" do
    ApplicationRecord.transaction do
      @record.update!(title: "foo")
      @record.update!(subtitle: "bar")
      @record.reload
    end
    assert_equal %w[title subtitle updated_at].sort, @record.attributes_committed.sort
  end

  test "#attributes_committed does not return attributes changed in the transaction when transaction is rolled back" do
    ApplicationRecord.transaction do
      @record.update!(title: "foo")
      raise ActiveRecord::Rollback
    end
    assert_nil @record.attributes_committed
  end
end
