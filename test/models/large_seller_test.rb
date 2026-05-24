# frozen_string_literal: true

require "test_helper"

class LargeSellerTest < ActiveSupport::TestCase
  setup do
    @user = users(:referrer_user)
  end

  test "create_if_warranted doesn't create a record if large seller already exists" do
    LargeSeller.create!(user: @user, sales_count: 1500)
    assert_no_difference -> { LargeSeller.count } do
      LargeSeller.create_if_warranted(@user)
    end
  end

  test "create_if_warranted doesn't create a record if sales count below lower limit" do
    fake_sales = Struct.new(:count).new(90)
    @user.stub(:sales, fake_sales) do
      assert_no_difference -> { LargeSeller.count } do
        LargeSeller.create_if_warranted(@user)
      end
    end
  end

  test "create_if_warranted creates a record if sales count above lower limit" do
    fake_sales = Struct.new(:count).new(7_000)
    @user.stub(:sales, fake_sales) do
      assert_difference -> { LargeSeller.count }, 1 do
        LargeSeller.create_if_warranted(@user)
      end
    end
    assert @user.reload.large_seller.present?
  end
end
