# frozen_string_literal: true

require "test_helper"

class UpdateCurrenciesWorkerTest < ActiveSupport::TestCase
  setup do
    @worker_instance = UpdateCurrenciesWorker.new
  end

  test "updates currencies for current date" do
    @worker_instance.currency_namespace.set("AUD", "0.1111")
    assert_equal "0.1111", @worker_instance.get_rate("AUD")

    @worker_instance.perform

    # In test this is a fixed rate read from a file
    assert_equal "0.969509", @worker_instance.get_rate("AUD")
  end
end
