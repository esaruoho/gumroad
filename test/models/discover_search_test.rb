require "test_helper"

class DiscoverSearchTest < ActiveSupport::TestCase
  test "can be created" do
    search = DiscoverSearch.create!(query: "entrepreneurship", ip_address: "127.0.0.1")
    assert search.persisted?
  end
end
