require "test_helper"

class YearlyStatTest < ActiveSupport::TestCase
  test "belongs to user" do
    assoc = YearlyStat.reflect_on_association(:user)
    assert_equal :belongs_to, assoc.macro
  end
end
