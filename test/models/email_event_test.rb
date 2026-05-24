# frozen_string_literal: true

require "test_helper"

class EmailEventTest < ActiveSupport::TestCase
  setup do
    skip "EmailEvent is a Mongoid model — MongoDB not available in Minitest CI lane. Covered by RSpec integration."
  end

  test "placeholder" do
    assert true
  end
end
